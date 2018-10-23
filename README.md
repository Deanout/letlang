# EOPL3's Let Language
This repository contains the implementation for the Let Language covered in Essentials of Programming Languages 3rd edition. The code is heavily commented, and contains some of the references used to construct it. The pdf lecture mentioned in the first reference is by far the most helpful so I definitely recommend reading through it.

## Tl;dr How Do I Run it?
Either call (run "let x = 5 in -(6,x)"), replacing the program in quotes with your program, or you can just call (repl) and use the handy Read-Eval-Print loop.

## Breakdown
The code is broken down into stages. I tried to implement things in the order the book presented them, and then added the SLLGEN boilerplate code at the end.

### Environment
The code can be run in DrRack... just kidding. I opted for the procedural implementation covered by EOPL3 on page 40. This was mainly due to preference, as any environment that satisfies the requirements of 2.2 will do.

1. empty-env just returns a procedure that will print an error if you try finding a variable inside of it.
2. extend-env allows you to add variables to the environment.
3. apply-env allows you to search an environment for a search variable.
4. test-env is simply an empty-env extended to contain three variables: x,y, and z. This environment isn't used in the program.

### Datatypes
Due to SLLGEN creating these datatypes for us, they've been commented out. That said, I've left them in so that you can see what SLLGEN is doing for you. The following datatypes were defined:

1. define-datatype program defines what a program is.
2. define-datatype expression defines what an expression is.

### Initial Environment
This version of the Let language doesn't allow you to define variables at runtime, save for temporarily with a let call, so any variable that we want to use will have to be fed into the initial environment. As such, we've initialized this environment with three values:

1. x 10
2. v 5
3. i 1

### Expressed Values
The expressed values are either a num-val or a bool-val. If you want to get the number out of a num-val, ex: (numval 5), you'll need the expval->num extractor.

1. num-val contains a number:   (num-val 5)
2. bool-val contains a boolean: (bool-val #f)
3. expval->num extracts the number from a num-val: (expval->num (num-val 5))
4. expval->bool extracts the bool from a bool-val: (expval->bool (bool-val #f))

### Interpreter
This contains a few key procedures that allow us to interpret our language. Most of this is covered in chapter 3 of EOPL3, but SLLGEN's scan&parse is covered in Appendix B.

1. run is the entry point.
2. value-of-program allows you to call value-of with our initial environment and the expression.
3. value-of contains the logic for each of our defined datatypes.

## SLLGEN
This was not covered sufficiently in the book, and even then it can only be found in Appendix B. SLLGEN requires two components:
1. A lexical specification that tells the program if whitespace matters or what a number is.
2. A grammar that tells you what each datatype looks like.

### Lexical Specification
The lexical specification has four rules with four potential actions, and each rule has three parts:

#### The Parts
Each lexical rule has three parts:
1. A name for the token.
2. A pattern of characters expressed as a regular expression.
3. An action to be taken by the scanner.

#### Potential Actions
Potential actions of the scanner are:
1. skip - ignore the input characters.
2. symbol - make a PL identifier.
3. number - make a literal number from the token string.
4. string - make a PL string literal from the token string.

### Grammar
The grammar is the second input parameter to the parser generator. A grammar is a list of production rules.
Each rule has three parts:
1. Left-Hand-Side (LHS) which specifies the non-terminal symbol of the corresponding PL BNF syntax rule (and the name of an abstract datatype)
2. Right-Hand-Side (RHS) which is a list of terminal symbols (punctuation and keywords) plus other non-terminal symbols in the grammar.
3. Production name which will be the name of the abstract datatype variant for the LHS datatype.

SLLGEN will automatically generate these abstract datatypes from the grammar.
Format: (non-terminal (production_name) terminal_and_other_non-terminal_symbols)

### SLLGEN Procedures
Four procedures are utilized from SLLGEN in this program.
1. sllgen:make-define-datatypes defines the datatypes for you, given the lex-spec and the grammar.
2. show-the-datatypes will print the datatypes for you if you run it. Highly recommend doing this at least once.
3. just-scan will print out what the scanner creates for you. Again, highly recommend doing this at least once.
4. scan&parse is used by our run procedure to do the scanning and parsing before feeding the program into value-of-program.
5. repl creates a Read-Eval-Print loop for you, allowing you to run the program continuously unless you error out or end it yourself.
