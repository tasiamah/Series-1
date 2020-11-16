module Complexity

import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

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