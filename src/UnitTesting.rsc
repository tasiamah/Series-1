module UnitTesting

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

list[loc] getAssertCount(list[Declaration] asts) {
	list[loc] asserts = [];
	
	visit(asts){
		case  a:\methodCall(bool isSuper, /(assert).*/, list[Expression] arguments): asserts += a.src;
    	case  a:\methodCall(bool isSuper, Expression receiver, /(assert).*/, list[Expression] arguments): asserts += a.src;
	}
	
	return asserts;
}