module Helpers

import IO;
import Set;
import List;
import Type;
import String;
import Map;

import Ranking;
import Volume;
import Helpers;
import Complexity;
import Duplication;
import UnitInterfacing;
import UnitTesting;

import util::Math;
import util::Benchmark;

import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

list[str] getLinesOfCode(loc file){
	list[str] linesOfCode = [];
	bool isMultiLineComment = false;
	
	list[str] fileLines = readFileLines(file);
	
	for (line <- fileLines) {
		switch(line) {
			case /^\s*$/: null;																			// checks blank lines
			case /^\s*\/\/.*/: null;																	// single line comments			
			case /^\s*(\/\*.*\*\/)\s*$/: null;															// check multiline comments on single line
			case /.*\s*(\/\*.*\*\/)\s*/ : if (!isMultiLineComment) linesOfCode += trim(line); 			// check '/*' or '*/' inside code lines
			case /^(\s*\/\*)/: isMultiLineComment = true;												// checks lines starting with whitespace and '/*' 
			case /\*\/\w*\s*$/: isMultiLineComment = false;												// check '*/' at line ending
			case /\".*((\/\*)+|(\*\/)+).*\"/: if (!isMultiLineComment) linesOfCode += trim(line);		// check '/* or *\' inside ""
			case /.*\/\*.*/: ({		
				if (!isMultiLineComment) {
					linesOfCode += trim(line);
					isMultiLineComment = true;
				}
			});
			case /.*\*\/\s*\/\/.*/: isMultiLineComment = false;	 										// check for multiline ending, that starts new multiline comment or has a comment on same line (without code)
			case /.*\*\/[\w\s]+/: ({																	// check for multiline ending, with code on same line (after)
				if (isMultiLineComment) {
					linesOfCode += trim(line);
					isMultiLineComment = false;
				}
				
			});
			
			//case /(\/\/|\/\*|\*\/)/: if (!isMultiLineComment) println(line);
			
						
			default: if (!isMultiLineComment) linesOfCode += trim(line);								// if everything above fails, it must be a line of code
		}			
	}
	
	return linesOfCode;
}

int countLinesOfCode (loc file){
	list[str] linesOfCode = getLinesOfCode(file);
	return size(linesOfCode);
}

list[Declaration] getASTs(M3 model){
	list[Declaration] asts = [];
	for (m <- model.containment, m[0].scheme == "java+compilationUnit"){
		asts += createAstFromFile(m[0], true);
	}
	
	return asts;
}

set[Declaration] getMethods(list[Declaration] asts) {
	set[Declaration] allMethods = {};
	
	visit(asts){
		case m:\method(Type _, str _, list[Declaration] _, list[Expression] _, Statement impl): allMethods += m;
    	case m:\method(Type _, str _, list[Declaration] _, list[Expression] _):  allMethods += m;
     	case m:\constructor(str _, list[Declaration] _, list[Expression] _, Statement ): allMethods += m;
     	case m:\initializer(Statement impl): allMethods += m;
	}
	
	return allMethods;
}

list[str] getProjectCodePerFile (list[loc] projectFiles){
	list[str] codeFiles = [];
	
	for (file <- projectFiles){
		list[str] fileLinesOfCode = getLinesOfCode(file);
		fileLinesOfCode += "*THE FILE ENDED*";
		codeFiles += fileLinesOfCode;
	}
	
	return codeFiles;
}

