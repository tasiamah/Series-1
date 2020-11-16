module Volume

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

int countProjectLinesOfCode(M3 projectLocation){
	int linesOfCode = 0;
	
	set[loc] projectFiles = files(projectLocation);
		
	for (file <- projectFiles) {
		linesOfCode += countLinesOfCode(file);
	}
	
	return linesOfCode;
}