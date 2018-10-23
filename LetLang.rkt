#lang racket
; Let Lang implementation
; Dean DeHart
; Oakland University

; References:
; 1. http://www.cs.sfu.ca/CourseCentral/383/havens/notes/Lecture11.pdf
; 2. https://github.com/mwand/eopl3/blob/master/chapter3/let-lang/lang.scm
; 3. EOPL 3rd Ed. By Daniel P. Friedman & Mitchell Wand, 2008.

; Need include for cases, define-datatype, etc.
(require (lib "eopl.ss" "eopl"))
; Environment (p. 40)

; Empty environment is an environment that will always return
; a binding not found error.
(define empty-env
  (lambda ()
    (lambda (search-var)
      (printf "There is no binding for the search var ~s in this environment." search-var)
      (newline))))

; Extend environment is an environment that will return a binding
; for a variable if at some point you called extend environment
; with that variable and a value.
(define extend-env
  (lambda (saved-var saved-val saved-env)
    (lambda (search-var)
      (if (eqv? search-var saved-var)
          saved-val
          (apply-env saved-env search-var)))))
; Apply environment takes in an environment and a search var
; and calls that environment (Which is an instance of the
; extend-env function that already has the values saved) to
; search for the value of the variable.
(define apply-env
  (lambda (env search-var)
    (env search-var)))

; Now let's create an environment to test with.
; Usage: (extend-env saved var saved val EnvToExtend)
(define test-env (extend-env `x 3 ; Extends one last time:    [x 3][y 4][z 5]p
                  (extend-env `y 4 ; Extends [z 5]p to be:         [y 4][z 5]p
                   (extend-env `z 5 ; Extends the original environment: [z 5]p
                    (empty-env))))) ; The original environment: p

; Datatype (Figure 3.6, p. 69)

; The define-datatype requires an include statement to work.
; Put this at the top of the file: (require (lib "eopl.ss" "eopl"))

; First we need to define what a program is.
; A program is an expression.
; Just as a note, an expression is not defined yet. See next definition
; for what an expression is.
(define-datatype program program?
  (a-program
   (exp1 expression?)))
; An expression comes in one of six forms.
; const-exp : int             -> Exp
; zero?-exp : Exp             -> Exp
; if-exp    : Exp * Exp * Exp -> Exp
; diff-exp  : Exp * Exp       -> Exp
; var-exp   : Var             -> Exp
; let-exp   : Var * Exp * Exp -> Exp
(define-datatype expression expression?
  (const-exp
   (num number?))
  (var-exp
   (var symbol?))
  (zero?-exp
   (exp1 expression?))
  (diff-exp
   (exp1 expression?)
   (exp2 expression?))
  (if-exp
   (exp1 expression?)
   (exp2 expression?)
   (exp3 expression?))
  (let-exp
   (var identifier?)
   (exp1 expression?)
   (body expression?)))

; Initial Environment (p. 69)

; We need an initial environment if we're going to test our language.
; This one will use our new datatypes, unlike test-env which used
; basic scheme values.
; Just as a note: num-val has not been defined yet. See next section
(define init-env
  (lambda ()
    (extend-env
     `i (num-val 1)
     (extend-env
      `v (num-val 5)
      (extend-env
       `x (num-val 10)
       (empty-env))))))
; Expressed Values (Figure 3.7, p. 70)

; This is our interface for the expressed values.
; As a reminder, our values can be:
; num-val : Int         -> ExpVal
; bool-val : Bool       -> ExpVal
; expval->num : ExpVal  -> Int
; expval->bool : ExpVal -> Bool
(define-datatype expval expval?
  (num-val
   (num number?))
  (bool-val
   (bool boolean?)))
(define expval->num
  (lambda (val)
    (cases expval val
      (num-val (num) num)
      (else (printf "Expected value extractor error: ~s ~s" `num val)))))
(define expval->bool
  (lambda (val)
    (cases expval val
      (bool-val (bool) bool)
      (else (printf "Expected value extractor error: ~s ~s" `bool val)))))

; The Interpreter for the Let Language (Figure 3.8-9, p. 71-72)

; The interpreter needs an entry point.
; Note: scan&parse is from a library in Appendix B. Needs a separate implementation
; that we'll cover at the end.
; run : String -> ExpVal
(define run
  (lambda (string)
    (value-of-program (scan&parse string))))
; This procedure allows us to call the value-of procedure
; with the initial environment. Think of it as a helper function.
; value-of-program : Program -> ExpVal
(define value-of-program
  (lambda (pgm)
    (cases program pgm
      (a-program (exp1)
                 (value-of exp1 (init-env))))))
; This procedure is the actual value-of procedure.
; value-of : Exp * Exp -> ExpVal
(define value-of
  (lambda (exp env)
    (cases expression exp
      (const-exp (num) (num-val num))
      (var-exp (var) (apply-env env var))
      (diff-exp (exp1 exp2)
                (let ([val1 (value-of exp1 env)]
                      [val2 (value-of exp2 env)])
                  (let ([num1 (expval->num val1)]
                        [num2 (expval->num val2)])
                    (num-val
                     (- num1 num2)))))
      (zero?-exp (exp1)
                 (let ([val1 (value-of exp1 env)])
                   (let ([num1 (expval->num val1)])
                     (if (zero? num1)
                         (bool-val #t)
                         (bool-val #f)))))
      (if-exp (exp1 exp2 exp3)
              (let ([val1 (value-of exp1 env)])
                (if (expval->bool val1)
                    (value-of exp2 env)
                    (value-of exp3 env))))
      (let-exp (var exp1 body)
               (let ([val1 (value-of exp1 env)])
                 (value-of body
                           (extend-env var val1 env)))))))

; Lexical specification of the language using SLLGen

#| Lexical rule formulation:
  Each lexical rule has three parts.
  1. A name for the token.
  2. A pattern of characters expressed as a regular expression.
  3. An action to be taken by the scanner.
  Potential actions of the scanner are:
  1. skip - ignore the input characters.
  2. symbol - make a PL identifier.
  3. number - make a literal number from the token string.
  4. string - make a PL string literal from the token string.
  The code below has comments which elaborate on this further.
|#
  (define the-lexical-spec
      '((whitespace (whitespace) skip) ; Skip the whitespace
        ; Any arbitrary string of characters following a "%" upto a newline are skipped.
        (comment ("%" (arbno (not #\newline))) skip)
        ; An identifier is a letter followed by an arbitrary number of contiguous digits,
        ; letters, or specified punctuation characters.
        (identifier
         (letter (arbno (or letter digit "_" "-" "?")))
         symbol)
        ; A number is any digit followed by an arbitrary number of digits
        ; or a "-" followed by a digit and an arbitrary number of digits.
        (number (digit (arbno digit)) number)
        (number ("-" digit (arbno digit)) number)))
#| Grammatical specification of the language
  The grammar is the second input parameter to the parser generator
  A grammar is a list of production rules.
  Each rule has three parts:
  1. Left-Hand-Side (LHS) which specifies the non-terminal symbol of the corresponding
     PL BNF syntax rule (and the name of an abstract datatype)
  2. Right-Hand-Side (RHS) which is a list of terminal symbols (punctuation and keywords)
     plus other non-terminal symbols in the grammar.
  3. Production name which will be the name of the abstract datatype variant for the
     LHS datatype.
  SLLGEN will automatically generate these abstract datatypes from the grammar.
  Format: (non-terminal (production_name) terminal_and_other_non-terminal_symbols)
|#
(define the-grammar
    '((program (expression) a-program)
      
      (expression (number) const-exp)
      (expression (identifier) var-exp)
      
      ; zero?-exp : zero?(a)
      (expression
       ("zero?" "(" expression ")")
       zero?-exp)
      
      ; diff-exp : -(a,b) -> (- a b)
      (expression
       ("-" "(" expression "," expression ")")
       diff-exp)
      
      ; if-exp : (if a then b else c)
      (expression
       ("if" expression "then" expression "else" expression)
       if-exp)
      

      ; let-exp : (let y = a in b)
      (expression
       ("let" identifier "=" expression "in" expression)
       let-exp)))

; Need SLLGen from Appendix B.

; This will generate the datatypes that we've previously defined
; by using the grammar's definition of them.
; This means you don't have to type our your define-datatypes,
; but it makes it feel like you're missing some steps.
;(sllgen:make-define-datatypes the-lexical-spec the-grammar)

; This allows you to print out the datatype definitions,
; which will let you remove the mystery that the previous
; call created.
(define show-the-datatypes
  (lambda () (sllgen:list-define-datatypes the-lexical-spec the-grammar)))

; To make a string parser from a set of lexical and grammar rules, use the
; procedure sllgen:make-string-parser
(define scan&parse
  (sllgen:make-string-parser the-lexical-spec the-grammar))

; Creates the scanner, this will provide you with the tokenized
; version of the program.
#| Given the lexical spec, calling just-scan on the following:
  foo bar x = 3 % comment
  will produce this:
  ((identifier foo)
   (identifier bar)
   (identifier x)
   (literal-string28 "=")
   (number 3))
|#
(define just-scan
  (sllgen:make-string-scanner the-lexical-spec the-grammar))

; Read Evaluate Print Loop
; This will allow you to run programs until you decide to press EOF.
(define repl
 (sllgen:make-rep-loop "--> "
 (lambda (pgm) (value-of-program pgm))
 (sllgen:make-stream-parser the-lexical-spec the-grammar)))

; Sample Program for testing purposes.
(define sp "let x = 5 in -(6,x)")