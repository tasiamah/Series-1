module main

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

int getTestLOC(list[loc] testFiles) {
	int testLOC = 0;
	for (class <- testFiles) {
		testLOC += countLinesOfCode(class);
	}
	return testLOC;
}

list[loc] getTestFiles(M3 model) {
	return [ f  | f <- files(model), startsWith(f.file, "Test")];
}

tuple[int, int, int] getMethodStats(Declaration method){
	int methodLines = countLinesOfCode(method.src);
	int methodComplexity = cyclomaticComplexity(method);
	int methodParameters = unitInterfacing(method);
	
	return <methodLines, methodComplexity, methodParameters>;
}

tuple[int, int, int, int] addStats (tuple[int, int, int, int] first, tuple[int, int, int, int] second){

	tuple[int, int, int, int] result = <0,0,0,0>;

	result[0] = first[0] + second[0];
	result[1] = first[1] + second[1];
	result[2] = first[2] + second[2];
	result[3] = first[3] + second[3];
	
	return result;
}

tuple [int, int, int, int] catagorizeComplexity(int cc, int lines){

	tuple[int, int, int, int] result = <0,0,0,0>;

	if (cc < 11) {result[0] += lines;}
	else if (cc < 21) {result[1] += lines;}
	else if (cc < 51) {result[2] += lines;}
	else {result[3] += lines;}
	
	return result;
}

tuple [int, int, int, int] catagorizeUnitSize(int lines){

	tuple[int, int, int, int] result = <0,0,0,0>;

	if (lines < 30) {result[0] += lines;}
	else if (lines < 44) {result[1] += lines;}
	else if (lines < 74) {result[2] += lines;}
	else {result[3] += lines;}
	
	return result;
	
}

tuple [int, int, int, int] catagorizeUnitInterfacing(int parameters, int lines){

	tuple[int, int, int, int] result = <0,0,0,0>;

	if (parameters < 2) {result[0] += lines;}
	else if (parameters < 3) {result[1] += lines;}
	else if (parameters < 4) {result[2] += lines;}
	else {result[3] += lines;}
	
	return result;
}

tuple[real, real, real, real] metricPercentages (tuple[int simple, int moderate, int complex, int unstable] metric, int lines){
	tuple[real simple, real moderate, real complex, real unstable] percentages = <metric.simple/toReal(lines)*100,
																				 metric.moderate/toReal(lines)*100,
																				 metric.complex/toReal(lines)*100,
																				 metric.unstable/toReal(lines)*100>;
																				
	return percentages;
}

str metricData(tuple [real simple, real moderate, real complex, real unstable] metric){
	return (
	"	Low:<metric.simple>%
	 Moderate:<metric.moderate>%
	 Complex:<metric.complex>%
	 Unstable:<metric.unstable>%
	");
}

void main(loc projectLocation) {
	M3 model = createM3FromEclipseProject(projectLocation);
	list[Declaration] asts = getASTs(model);
	set[Declaration] projectMethods = getMethods(asts);
	
	println("
	
	========= VOLUME ==========
	
	");
	
	int totalLinesOfCode = countProjectLinesOfCode(model);
	str volumeRank = rankVolume(totalLinesOfCode);
	println("Lines of code: <totalLinesOfCode> rank: <volumeRank> grade: <rankToGrade(volumeRank)>");
	
	map[loc, tuple[int, int, int]] unitStats = ();
	
	tuple[int simple, int moderate, int complex, int unstable] complexityPerUnit = <0, 0, 0, 0>;
	tuple[int simple, int moderate, int complex, int unstable] sizePerUnit = <0, 0, 0, 0>;
	tuple[int simple, int moderate, int complex, int unstable] interfacingPerUnit = <0, 0, 0, 0>;
	
	int totalComplexity = 0;
	
	for (method <- projectMethods) {

		tuple[int lines, int complexity, int parameters] stats = getMethodStats(method);
		
		complexityPerUnit = addStats(complexityPerUnit, catagorizeComplexity(stats.complexity, stats.lines));
		sizePerUnit = addStats(sizePerUnit, catagorizeUnitSize(stats.lines));
		interfacingPerUnit = addStats(interfacingPerUnit, catagorizeUnitInterfacing(stats.parameters, stats.lines));
		
		unitStats[method.src] = stats;
		totalComplexity += stats.complexity;
	}
		
	list[loc] testFiles = getTestFiles(model);
	int testLOC = getTestLOC(testFiles);
	int assertCount = size(getAssertCount(asts));
	
	tuple[real simple, real moderate, real complex, real unstable] percentagesComplexity = metricPercentages(complexityPerUnit,totalLinesOfCode);
	tuple[real simple, real moderate, real complex, real unstable] percentagesVolume = metricPercentages(sizePerUnit, totalLinesOfCode);
	tuple[real simple, real moderate, real complex, real unstable] percentagesInterfacing = metricPercentages(interfacingPerUnit, totalLinesOfCode);
						
	println("
	
	========= COMPLEXITY ==========
	
	");					
																					
	str complexityRank = rankComplexity(percentagesComplexity);									
	println(metricData(percentagesComplexity));
	println("Complexity rank: <complexityRank>");
	
	println("
	
	========= UNIT SIZE ==========
	
	");
	
	str unitVolumeRank = rankUnitSize(percentagesVolume);
	println(metricData(percentagesVolume));
	println("Unit Size rank: <unitVolumeRank>");
	
	println("
	
	========= INTERFACING ==========
	
	");
	
	str interfacingRank = rankInterfacing(percentagesInterfacing);
	println(metricData(percentagesInterfacing));
	println("Interfacing rank: <interfacingRank>");
	
	println("
	
	========= DUPLICATION ==========
	
	");
	
	int dupLines = codeDuplication(model);
	real dupLinesPercentage = dupLines / toReal(totalLinesOfCode) * 100;
	
	str duplicationRank = rankDuplication(dupLinesPercentage);
	println("Duplication: <dupLines> percentage: <dupLinesPercentage>% rank: <duplicationRank>");
	
	println("
	
	========= UNIT TESTING ==========
	
	");
	
		
	real assertionDensity = (assertCount / toReal(testLOC) * 100);
	real assertionMcCabe = (assertCount / toReal(totalComplexity));
	str densityRank = rankAssertionDensity(assertionDensity);
	str mcCabeRank = rankAssertionMcCabe(assertionMcCabe);
	str unitTestRank = rankUnitTest(densityRank, mcCabeRank);
	
	println(
	"
	assertionDensity: <assertionDensity> rank: <densityRank>
	assertionMcCabe: <assertionMcCabe> rank: <mcCabeRank>
	Unit Test Rank (average): <unitTestRank>
	");
	
	tuple[str volume, str complexity, str unitVolume, str duplication, str unitInterfacing, str unitTest] ranks = < volumeRank, complexityRank, unitVolumeRank, duplicationRank, interfacingRank, unitTestRank>;
	//println(ranks);
	
	println("
	
	========= FINAL RANKINGS ==========
	
	");
	
	println("Project wide Analysability ranking: <rankAnalysability(ranks.volume, ranks.duplication, ranks.unitVolume)>");
	println("Project wide Changeability ranking: <rankChangeability(ranks.complexity, ranks.duplication)>");
	println("Project wide Stability ranking: <rankStability(ranks.unitTest)>");
	println("Project wide Testability ranking: <rankTestability(ranks.complexity, ranks.unitVolume, ranks.unitTest)>");
	
}

void makeReport(){
	println(benchmark( ("Smallsql" : void() {main(|project://smallsql0.21_src|);})));
}