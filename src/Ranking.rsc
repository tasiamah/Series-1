module Ranking

import util::Math;


str rankComplexity(tuple[real simple, real moderate, real complex, real unstable] complexityPerUnit){
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

str rankUnitSize(tuple[real simple, real moderate, real complex, real unstable] sizePerUnit){
	if (sizePerUnit.moderate <=  19.5 &&
		sizePerUnit.complex == 10.9 &&
		sizePerUnit.unstable == 3.9) return "++";
		
	if (sizePerUnit.moderate <= 26.0  &&
		sizePerUnit.complex <= 15.5 &&
		sizePerUnit.unstable == 6.5) return "+";
		
	if (sizePerUnit.moderate <=  34.1 &&
		sizePerUnit.complex <= 22.2 &&
		sizePerUnit.unstable == 11) return "o";
		
	if (sizePerUnit.moderate <= 45.9 &&
		sizePerUnit.complex <= 31.4 &&
		sizePerUnit.unstable <= 18.1) return "-";
	
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

str rankAssertionDensity(real density){
	if (density > 18.9) return "++";
	if (density > 10) return "+";
	if (density > 7.2) return "o";
	if (density > 1.5) return "-";
	return "--";
}

str rankAssertionMcCabe(real ratio){
	if (ratio > 1.025) return "++";
	if (ratio > 0.427) return "+";
	if (ratio > 0.187) return "o";
	if (ratio > 0.007) return "-";
	return "--";
}

str rankUnitTest(str density, str ratio){
	int gradeDensity = rankToGrade(density);
	int gradeRatio = rankToGrade(ratio);
	
	int grade = floor((gradeDensity + gradeRatio) / 2.0);
	return gradeToRank(grade);
}

str rankTestability(str complexity, str uSize, str uTest){
	int gradeComp = rankToGrade(complexity);
	int gradeuSize = rankToGrade(uSize);
	int gradeuTest = rankToGrade(uTest);
	
	int grade = floor((gradeComp + gradeuSize + gradeuTest) / 3.0);
	return gradeToRank(grade);
}

str rankStability(str unitTestRank) = unitTestRank;


int rankToGrade(str rank){
	int grade = 0;
	switch(rank){
		case "++" : grade = 5;
		case "+" : grade = 4;
		case "o" : grade = 3;
		case "-" : grade = 2;
		case "--" : grade = 1;
	}
	return grade;
}

str gradeToRank(int grade){
	str rank = "";
	switch(grade){
		case 5 : rank = "++";
		case 4 : rank = "+";
		case 3 : rank = "o";
		case 2 : rank = "-";
		case 1 : rank = "--";
	}
	return rank;
}

str rankAnalysability(str vol, str dup, str usize){
	int gradeVol = rankToGrade(vol);
	int gradeDup = rankToGrade(dup);
	int gradeUSize = rankToGrade(usize);
	
	int grade = floor((gradeVol + gradeDup + gradeUSize) / 3.0);
	return gradeToRank(grade);
}

str rankChangeability(str complexity, str dup){
	int gradeComp = rankToGrade(complexity);
	int gradeDup = rankToGrade(dup);
	
	int grade = floor((gradeComp + gradeDup) / 2.0);
	return gradeToRank(grade);
}

str rankMaintainability(str analysability, str changeability, str stability, str testability){
	int gradeAnalysability = rankToGrade(analysability);
	int gradeChangeability = rankToGrade(changeability);
	int gradeTestability = rankToGrade(testability);
	int gradeStability = rankToGrade(stability);
	
	int grade = floor((gradeAnalysability + gradeChangeability + gradeTestability + gradeStability) / 4.0);
	return gradeToRank(grade);
}
