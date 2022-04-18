# ampbl
A Mui Pequena e Besta Linguagem

Or: The Little Dumb Language

This niche language was created to facilitate the translation of '|' separated files from one format to another by reading each field and transforming it according to a rule encoded in this language, which vaguely resembles LISP.

The parser reads strings in the format (OP;OPERAND1;OPERAND2;...;OPERANDK) and returns the result to the caller. There is a handful of built in relational and arithmetic operators, a conditional operator (but no loops), and a sequential operator that its only job is to parse each of its fields in sequence until its end, which provides a way of building little programs with it.

The example that comes with this repository in Main.ps1 is a little and rather inefficient program to decide whether a number is prime or not by taking its modulo against the nmbers 2, 3, 5 and 7.

Ex.:

(?;(>=;(^;%2;%3);%6);%Greater;%Smaller)

This is equivalent (in C) to:

if (pow(2.0, 3.0) >= 6)
    return "Greater";
else
    return "Smaller";

This is a work in progress, so some code pieces in the DataFuncs.ps1 are going tobe bogus or test stuff. But, overall, the code is kind of pretty. It may be of some curiosity to you. You're welcome to tinker about with it.
