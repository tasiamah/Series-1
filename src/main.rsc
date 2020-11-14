module main

import IO;
import Set;
import List;
import Type;
import String;
import Map;

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

int cyclomaticComplexity(Declaration method){
	int complexity = 1;
		
	visit(method){
		case \for(_, _, _, _): complexity +=1;
		case \for(_,_,_): complexity +=1;
		case \while(_,_): complexity +=1;
		case \if(_,_): complexity +=1;
		case \if(_,_,_): complexity +=1;
		case \case(_): complexity +=1;
		case \catch(_, _): complexity +=1;
		case \conditional(_,_,_): complexity +=1;
		case \foreach(_, _, _): complexity +=1;
		case \do(_,_): complexity +=1;
		case \infix(_,"&&",_) : complexity +=1;
        case \infix(_,"||",_) : complexity +=1;
	}

	return complexity;
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

int codeDuplication(M3 model){
	list[loc] javaFiles = toList(files(model));
	list[str] projectCode = getProjectCodePerFile(javaFiles);
	map[int freq, set[str] duplicateLines] linesMap = domainX(invert(distribution(projectCode)), {1});
	set[str] duplicateLines = ({} | it + line | line <- linesMap.duplicateLines);
	map[str line, list[int] indeces] indexMap = domainR(toMap(zip(projectCode, [0..size(projectCode)])), duplicateLines);
	
	list[int] duplicateIndices = [];
	for (line <- indexMap) duplicateIndices += indexMap[line];
	duplicateIndices = sort(duplicateIndices);

	map[list[str] lines, list[list[int]] indeces] blockIndex = ();
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

int countProjectLinesOfCode(M3 projectLocation){
	int linesOfCode = 0;
	
	set[loc] projectFiles = files(projectLocation);
		
	for (file <- projectFiles) {
		linesOfCode += countLinesOfCode(file);
	}
	
	return linesOfCode;
}

str rankComplexityAndVolume(tuple[real simple, real moderate, real complex, real unstable] complexityPerUnit){
	if (complexityPerUnit.moderate <= 25 &&
		complexityPerUnit.complex == 0 &&
		complexityPerUnit.unstable == 0) return "++";
		
	if (complexityPerUnit.moderate <= 30 &&
		complexityPerUnit.complex <= 5 &&
		complexityPerUnit.unstable == 0) return "+";
		
	if (complexityPerUnit.moderate <= 40 &&
		complexityPerUnit.complex <= 10 &&
		complexityPerUnit.unstable == 0) return "o";
		
	if (complexityPerUnit.moderate <= 50 &&
		complexityPerUnit.complex <= 15 &&
		complexityPerUnit.unstable <= 5) return "-";
	
	return "--";
}

str rankDuplication(real percentage){
	if (percentage < 3) return "++";
	if (percentage < 5) return "+";
	if (percentage < 10) return "o";
	if (percentage < 20) return "-";
	return "--";
}


str rankVolume(int linesOfCode){
	if (linesOfCode < 66000) return "++";
	if (linesOfCode < 246000) return "+";
	if (linesOfCode < 665000) return "o";
	if (linesOfCode < 1310000) return "-";
	return "--";
}

str rankInterfacing(tuple[real simple, real moderate, real complex, real unstable] interfacingPerUnit){
	if (interfacingPerUnit.moderate <= 12.1 &&
		interfacingPerUnit.complex == 5.4 &&
		interfacingPerUnit.unstable == 2.2) return "++";
		
	if (interfacingPerUnit.moderate <= 14.9 &&
		interfacingPerUnit.complex <= 7.2 &&
		interfacingPerUnit.unstable == 3.1) return "+";
		
	if (interfacingPerUnit.moderate <= 17.7 &&
		interfacingPerUnit.complex <= 10.2 &&
		interfacingPerUnit.unstable == 4.8) return "o";
		
	if (interfacingPerUnit.moderate <=  25.2 &&
		interfacingPerUnit.complex <= 15.3 &&
		interfacingPerUnit.unstable <=  7.1) return "-";
	
	return "--";
}

int unitInterfacing(Declaration method){
	int numberOfParameters = 0;

	visit (method){
		case \parameter(Type \type, str name, int extraDimensions) : numberOfParameters += 1;
	}
	
	return numberOfParameters;
}

void main() {
	loc projectLocation = |project://sample|;
	M3 model = createM3FromEclipseProject(projectLocation);
	list[Declaration] asts = getASTs(model);
	set[Declaration] projectMethods = getMethods(asts);
	
	int totalLinesOfCode = countProjectLinesOfCode(model);
	
	str volumeRank = rankVolume(totalLinesOfCode);
	
	println("Lines of code: <totalLinesOfCode> rank: <volumeRank>");
	
	map[loc, tuple[int, int, int]] unitStats = ();
	
	tuple[int simple, int moderate, int complex, int unstable] complexityPerUnit = <0, 0, 0, 0>;
	tuple[int simple, int moderate, int complex, int unstable] sizePerUnit = <0, 0, 0, 0>;
	tuple[int simple, int moderate, int complex, int unstable] interfacingPerUnit = <0, 0, 0, 0>;
	
	for (method <- projectMethods) {

		int methodLines = countLinesOfCode(method.src);
		int methodComplexity = cyclomaticComplexity(method);
		int methodParameters = unitInterfacing(method);
				
		if (methodComplexity < 11) {complexityPerUnit.simple += methodLines;}
		else if (methodComplexity < 21) {complexityPerUnit.moderate += methodLines;}
		else if (methodComplexity < 51) {complexityPerUnit.complex += methodLines;}
		else {complexityPerUnit.unstable += methodLines;}
		
		if (methodLines < 15) {sizePerUnit.simple += methodLines;}
		else if (methodLines < 30) {sizePerUnit.moderate += methodLines;}
		else if (methodLines < 60) {sizePerUnit.complex += methodLines;}
		else {sizePerUnit.unstable += methodLines;}
		
		if (methodParameters < 2) {interfacingPerUnit.simple += methodLines;}
		else if (methodParameters < 3) {interfacingPerUnit.moderate += methodLines;}
		else if (methodParameters < 4) {interfacingPerUnit.complex += methodLines;}
		else {interfacingPerUnit.unstable += methodLines;}
		
		unitStats[method.src] = <methodLines, methodComplexity, methodParameters>;
	}
	
	iprintln(unitStats);
	
	tuple[real simplePercent, real moderatePercent, real complexPercent, real unstablePercent] percentagesComplexity = <complexityPerUnit.simple/toReal(totalLinesOfCode)*100,
																										 complexityPerUnit.moderate/toReal(totalLinesOfCode)*100,
																										 complexityPerUnit.complex/toReal(totalLinesOfCode)*100,
																										 complexityPerUnit.unstable/toReal(totalLinesOfCode)*100>;
																										 
 	tuple[real simplePercent, real moderatePercent, real complexPercent, real unstablePercent] percentagesVolume = <sizePerUnit.simple/toReal(totalLinesOfCode)*100,
																										 sizePerUnit.moderate/toReal(totalLinesOfCode)*100,
																										 sizePerUnit.complex/toReal(totalLinesOfCode)*100,
																										 sizePerUnit.unstable/toReal(totalLinesOfCode)*100>;
																										 
	tuple[real simplePercent, real moderatePercent, real complexPercent, real unstablePercent] percentagesInterfacing = <interfacingPerUnit.simple/toReal(totalLinesOfCode)*100,
																										 interfacingPerUnit.moderate/toReal(totalLinesOfCode)*100,
																										 interfacingPerUnit.complex/toReal(totalLinesOfCode)*100,
																										 interfacingPerUnit.unstable/toReal(totalLinesOfCode)*100>;
																										
	str complexityRank = rankComplexityAndVolume(percentagesComplexity);
																
	println("");
	println("Unit Complexity: (Low:<percentagesComplexity.simplePercent>%
	 Moderate:<percentagesComplexity.moderatePercent>%
	 Complex:<percentagesComplexity.complexPercent>%
	 Unstable:<percentagesComplexity.unstablePercent>%
	 rank: <complexityRank>)
	");
	
	str unitVolumeRank = rankComplexityAndVolume(percentagesComplexity);
	 
	println("Unit Volume: (Low:<percentagesVolume.simplePercent>%
	 Moderate:<percentagesVolume.moderatePercent>%
	 Complex:<percentagesVolume.complexPercent>%
	 Unstable:<percentagesVolume.unstablePercent>%
	 rank: <unitVolumeRank>)
	");
	
	str interfacingRank = rankInterfacing(percentagesInterfacing);
	
	println("Unit Interfacing: (Low:<percentagesInterfacing.simplePercent>%
	 Moderate:<percentagesInterfacing.moderatePercent>%
	 Complex:<percentagesInterfacing.complexPercent>%
	 Unstable:<percentagesInterfacing.unstablePercent>%
	 rank: <interfacingRank>)
	");
	
	int dupLines = codeDuplication(model);
	real dupLinesPercentage = dupLines / toReal(totalLinesOfCode) * 100;
	
	str duplicationRank = rankDuplication(dupLinesPercentage);
	println("Duplication: <dupLines> percentage: <dupLinesPercentage>% rank: <duplicationRank>");
	
	tuple[str volume, str complexity, str unitVolume, str duplication, str unitInterfacing] ranks = < volumeRank, complexityRank, unitVolumeRank, duplicationRank, interfacingRank>;
	println(ranks);
	
}

void makeReport(){
	println(benchmark( ("Duplication" : main) ));
}