;;;; Cyclone Scheme
;;;; https://github.com/justinethier/cyclone
;;;;
;;;; Copyright (c) 2014-2019, Justin Ethier
;;;; All rights reserved.
;;;;
;;;; This module makes it easier to interface directly with C code using the FFI.
;;;;
(define-library (cyclone foreign)
 (import
   (scheme base)
   (scheme eval)
   (scheme write) ;; TODO: debugging only!
   ;(scheme cyclone pretty-print)
   (scheme cyclone util)
 )
 ;(include-c-header "<ck_pr.h>")
 (export
   c-code
   c-value
   c-define
   c->scm
   scm->c
   c-define-type
 )
 (begin
   ;; 
   ;;(eval `(define *foreign-types* (list)))

  ;; (c-define-type name type (pack (unpack)))
  (define-syntax c-define-type
    (er-macro-transformer
      (lambda (expr rename compare)
        (let ((name (cadr expr))
              (type (cddr expr)))
          (unless (eval '(with-handler (lambda X #f) *foreign-types*))
            (write "no foreign type table" (current-error-port))
            (newline (current-error-port))
            (eval `(define *foreign-types* (make-hash-table))))
          (eval `(hash-table-set! *foreign-types* (quote ,name) (quote ,type)))
          #f))))

  (define-syntax c-value
    (er-macro-transformer
      (lambda (expr rename compare)
        (let* ((code-arg (cadr expr))
               (type-arg (caddr expr))
               (c-type (eval `(with-handler 
                                (lambda X #f)
                                (hash-table-ref *foreign-types* (quote ,type-arg))
                                )))
               (c-ret-convert #f)
              )
          (when c-type
            (write `(defined c type ,c-type) (current-error-port))
            (newline (current-error-port))
            (set! type-arg (car c-type))
            (if (= 3 (length c-type))
                (set! c-ret-convert (caddr c-type))))

          ;(for-each
          ;  (lambda (arg)
          ;    (if (not (string? arg))
          ;        (error "c-value" "Invalid argument: string expected, received " arg)))
          ;  (cdr expr))

          (if c-ret-convert
            `((lambda () (,c-ret-convert (Cyc-foreign-value ,code-arg ,(symbol->string type-arg)))))
            `((lambda () (Cyc-foreign-value ,code-arg ,(symbol->string type-arg))))
          )
          ))))

  (define-syntax c-code
    (er-macro-transformer
      (lambda (expr rename compare)
        (for-each
          (lambda (arg)
            (if (not (string? arg))
                (error "c-code" "Invalid argument: string expected, received " arg)))
          (cdr expr))
        `(Cyc-foreign-code ,@(cdr expr)))))

  ;; Unbox scheme object
  ;;
  ;; scm->c :: string -> symbol -> string
  ;;
  ;; Inputs:
  ;;  - code - C variable used to reference the Scheme object
  ;;  - type - Data type of the Scheme object
  ;; Returns:
  ;;  - C code used to unbox the data
  ;(define (scm->c code type)
  (define-syntax scm->c
    (er-macro-transformer
      (lambda (expr rename compare)
        (let ((code (cadr expr))
              (type (caddr expr)))
         `(case ,type
            ((int integer)
             (string-append "obj_obj2int(" ,code ")"))
            ((double float)
             (string-append "double_value(" ,code ")"))
            ((bignum bigint)
             (string-append "bignum_value(" ,code ")"))
            ((bool)
             (string-append "(" ,code " == boolean_f)"))
            ((char)
             (string-append "obj_obj2char(" ,code ")"))
            ((string)
             (string-append "string_str(" ,code ")"))
            ((symbol)
             (string-append "symbol_desc(" ,code ")"))
            ((bytevector)
             (string-append "(((bytevector_type *)" ,code ")->data)"))
            ((opaque)
             (string-append "opaque_ptr(" ,code ")"))
            (else
              (error "scm->c unable to convert scheme object of type " ,type)))))))
  
  ;; Box C object, basically the meat of (c-value)
  ;;
  ;; c->scm :: string -> symbol -> string
  ;;
  ;; Inputs:
  ;;  - C expression
  ;;  - Data type used to box the data
  ;; Returns:
  ;;  - Allocation code?
  ;;  - C code
  (define-syntax c->scm
   (er-macro-transformer
    (lambda (expr rename compare)
      (let ((code (cadr expr))
            (type (caddr expr)))
       `(case (if (string? ,type)
                  (string->symbol ,type)
                  ,type)
          ((int integer)
           (cons
             ""
             (string-append "obj_int2obj(" ,code ")")))
          ((float double)
           (let ((var (mangle (gensym 'var))))
           (cons
             (string-append 
               "make_double(" var ", " ,code ");")
             (string-append "&" var)
           )))
          ((bool)
           (cons
             ""
             (string-append "(" ,code " == 0 ? boolean_f : boolean_t)")))
          ((char)
           (cons
             ""
             (string-append "obj_char2obj(" ,code ")")))
          ((string)
           (let ((var (mangle (gensym 'var))))
           (cons
             (string-append 
               "make_double(" var ", " ,code ");")
             (string-append "&" var)
           )))
;      /*bytevector_tag */ , "bytevector"
;      /*c_opaque_tag  */ , "opaque"
;      /*bignum_tag    */ , "bignum"
;      /*symbol_tag    */ , "symbol"
          (else
            (error "c->scm unable to convert C object of type " ,type)))))))
  
  ;(pretty-print (
  (define-syntax c-define
    (er-macro-transformer
      (lambda (expr rename compare)
        (let* ((scm-fnc (cadr expr))
               (scm-fnc-wrapper (gensym 'scm-fnc))
               (c-fnc (cadddr expr))
               (rv-type (caddr expr))
               ;; boolean - Are we returning a custom (user-defined) type?
               (rv-cust-type (eval `(with-handler 
                                (lambda X #f)
                                (hash-table-ref *foreign-types* (quote ,rv-type))
                                )))
               ;; boolean - Does the custom return type have a conversion function?
               (rv-cust-convert
                 (if (and rv-cust-type (= 3 (length rv-cust-type)))
                     (caddr rv-cust-type)
                     #f))
               (arg-types (cddddr expr))
               (arg-syms/unbox 
                 (map 
                   (lambda (type)
                     (let ((var (mangle (gensym 'arg)))
                           (arg-cust-type (eval `(with-handler 
                                (lambda X #f)
                                (hash-table-ref *foreign-types* (quote ,type))
                                )))
                           )
                       (cons 
                         var 
                         (scm->c 
                           var 
                           (if arg-cust-type
                               (car arg-cust-type)
                               type))
                         ;(string-append "string_str(" var ")")
                         )))
                   arg-types))
               (returns
                 (c->scm 
                   (string-append 
                     c-fnc "(" (string-join (map cdr arg-syms/unbox) ",") ")")
                   (if rv-cust-type
                       (car rv-cust-type)
                       rv-type)))
               (return-alloc (car returns))
               (return-expr (cdr returns))
               (args (string-append
                       "(void *data, int argc, closure _, object k " 
                       (apply string-append 
                         (map
                           (lambda (sym/unbox)
                             (string-append ", object " (car sym/unbox)))
                         arg-syms/unbox))
                        ")"))
               (body
               ;; TODO: need to unbox all args, pass to C function, then box up the result
                 (string-append
                   return-alloc
                   "return_closcall1(data, k, " return-expr ");"))
              )
        (cond
          TODO: need to know if there any custom types for args with an arg-convert function, and need to handle those in case below.
                also need to handle case where there are custom arg conversion but not a custom return type conversion
          (rv-cust-convert
           (let ((arg-syms (map (lambda (a) (gensym 'arg)) arg-types)))
             `(begin
                (define-c ,scm-fnc-wrapper ,args ,body)
                (define (,scm-fnc ,@arg-syms)
                  (,rv-cust-convert
                    (,scm-fnc-wrapper ,@arg-syms))))))
          (else
           `(define-c ,scm-fnc ,args ,body)))
          ))))
  ; '(c-define scm-strlen int "strlen" string)
  ; list
  ; list))

 )
)
