module Duplication

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

int codeDuplication(M3 model){
	list[loc] javaFiles = toList(files(model));
	list[str] projectCode = getProjectCodePerFile(javaFiles);
	
	// make map with all indices of lines
	map[int freq, set[str] duplicateLines] linesMap = domainX(invert(distribution(projectCode)), {1});
	set[str] duplicateLines = ({} | it + line | line <- linesMap.duplicateLines);
	map[str line, list[int] indeces] indexMap = domainR(toMap(zip(projectCode, [0..size(projectCode)])), duplicateLines);
	
	// make list with all indices that are duplicates
	list[int] duplicateIndices = [];
	for (line <- indexMap) duplicateIndices += indexMap[line];
	duplicateIndices = sort(duplicateIndices);
	
	// make map with lines : list of blocks
	// all duplicate block lines are stored in duplicateBlocks, for speed
	map[list[str] lines, list[list[int]] indeces] blockIndex = ();
	
	// contains all blocks of line that are duplicates
	list[list[str]] duplicateBlocks = [];
	
	for (i <- duplicateIndices) {
		list[int] range = [i..i+6];
		list[str] code = projectCode[i..i+6];
		if ("*THE FILE ENDED*" notin code && range <= duplicateIndices) {
			if (code in blockIndex) {
				blockIndex[code] += [range];
				duplicateBlocks += [code];
			} else {
				blockIndex[code] = [range];
			}				
		}
	}
			
	set[int] duplicatedLines = {};
	
	for (block <- duplicateBlocks) {
		for (block2 <- blockIndex[block]){
			duplicatedLines += {*block2};
		}
	}
	
	return size(duplicatedLines);
}
