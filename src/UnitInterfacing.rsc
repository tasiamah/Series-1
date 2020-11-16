module UnitInterfacing

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

int unitInterfacing(Declaration method){
	int numberOfParameters = 0;

	visit (method){
		case \parameter(Type \type, str name, int extraDimensions) : numberOfParameters += 1;
	}
	
	return numberOfParameters;
}