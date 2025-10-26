package extensions.hscript;

import crowplexus.hscript.Parser;
import crowplexus.hscript.*;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Tools;

using crowplexus.hscript.Tools;

using StringTools;

/**
 * Extended to read the `public` keyword.
 */
class ParserEx extends Parser
{
	override function parseStructure(id)
	{
		#if hscriptPos
		var p1 = tokenMin;
		#end
		return switch (id)
		{
			case "if":
				ensure(TPOpen);
				var cond = parseExpr();
				ensure(TPClose);
				var e1 = parseExpr();
				var e2 = null;
				var semic = false;
				var tk = token();
				if (tk == TSemicolon)
				{
					semic = true;
					tk = token();
				}
				if (Type.enumEq(tk, TId("else"))) e2 = parseExpr();
				else
				{
					push(tk);
					if (semic) push(TSemicolon);
				}
				mk(EIf(cond, e1, e2), p1, (e2 == null) ? tokenMax : pmax(e2));
			case "var", "final":
				var ident = getIdent();
				var tk = token();
				var t = null;
				if (tk == TDoubleDot && allowTypes)
				{
					t = parseType();
					tk = token();
				}
				var e = null;
				if (Type.enumEq(tk, TOp("="))) e = parseExpr();
				else push(tk);
				mk(EVar(ident, t, e, id == "final"), p1, (e == null) ? tokenMax : pmax(e));
				
			case "while":
				var econd = parseExpr();
				var e = parseExpr();
				mk(EWhile(econd, e), p1, pmax(e));
			case "do":
				var e = parseExpr();
				var tk = token();
				switch (tk)
				{
					case TId("while"): // Valid
					default: unexpected(tk);
				}
				var econd = parseExpr();
				mk(EDoWhile(econd, e), p1, pmax(econd));
			case "for":
				ensure(TPOpen);
				var vname = getIdent();
				ensureToken(TId("in"));
				var eiter = parseExpr();
				ensure(TPClose);
				var e = parseExpr();
				mk(EFor(vname, eiter, e), p1, pmax(e));
			case "break": mk(EBreak);
			case "continue": mk(EContinue);
			case "else": unexpected(TId(id));
			case "inline":
				if (!maybe(TId("function"))) unexpected(TId("inline"));
				return parseStructure("function");
			case "function":
				var tk = token();
				var name = null;
				switch (tk)
				{
					case TId(id): name = id;
					default: push(tk);
				}
				var inf = parseFunctionDecl();
				mk(EFunction(inf.args, inf.body, name, inf.ret), p1, pmax(inf.body));
			case "return":
				var tk = token();
				push(tk);
				var e = if (tk == TSemicolon) null else parseExpr();
				mk(EReturn(e), p1, if (e == null) tokenMax else pmax(e));
			case "new":
				var a = new Array();
				a.push(getIdent());
				while (true)
				{
					var tk = token();
					switch (tk)
					{
						case TDot:
							a.push(getIdent());
						case TPOpen:
							break;
						default:
							unexpected(tk);
							break;
					}
				}
				var args = parseExprList(TPClose);
				mk(ENew(a.join("."), args), p1);
			case "throw":
				var e = parseExpr();
				mk(EThrow(e), p1, pmax(e));
			case "try":
				var e = parseExpr();
				ensureToken(TId("catch"));
				ensure(TPOpen);
				var vname = getIdent();
				ensure(TDoubleDot);
				var t = null;
				if (allowTypes) t = parseType();
				else ensureToken(TId("Dynamic"));
				ensure(TPClose);
				var ec = parseExpr();
				mk(ETry(e, vname, t, ec), p1, pmax(ec));
			case "switch":
				var parentExpr = parseExpr();
				var def = null, cases = [];
				ensure(TBrOpen);
				while (true)
				{
					var tk = token();
					switch (tk)
					{
						case TId("case"):
							var c:SwitchCase = {values: [], expr: null, ifExpr: null};
							cases.push(c);
							while (true)
							{
								var e = parseExpr();
								c.values.push(e);
								tk = token();
								switch (tk)
								{
									case TComma:
										// next expr
									case TId("if"):
										// if( Type.enumEq(e, EIdent("_")) )
										//	unexpected(TId("if"));
										
										var e = parseExpr();
										c.ifExpr = e;
										switch tk = token()
										{
											case TComma:
											case TDoubleDot: break;
											case _:
												unexpected(tk);
												break;
										}
									case TDoubleDot:
										break;
									default:
										unexpected(tk);
										break;
								}
							}
							var exprs = [];
							while (true)
							{
								tk = token();
								push(tk);
								switch (tk)
								{
									case TId("case"), TId("default"), TBrClose:
										break;
									case TEof if (resumeErrors):
										break;
									default:
										parseFullExpr(exprs);
								}
							}
							c.expr = if (exprs.length == 1) exprs[0]; else if (exprs.length == 0) mk(EBlock([]), tokenMin,
								tokenMin); else mk(EBlock(exprs), pmin(exprs[0]), pmax(exprs[exprs.length - 1]));
								
							for (i in c.values)
							{
								switch Tools.expr(i)
								{
									case EIdent("_"):
										def = c.expr;
									case _:
								}
							}
						case TId("default"):
							if (def != null) unexpected(tk);
							ensure(TDoubleDot);
							var exprs = [];
							while (true)
							{
								tk = token();
								push(tk);
								switch (tk)
								{
									case TId("case"), TId("default"), TBrClose:
										break;
									case TEof if (resumeErrors):
										break;
									default:
										parseFullExpr(exprs);
								}
							}
							def = if (exprs.length == 1) exprs[0]; else if (exprs.length == 0) mk(EBlock([]), tokenMin,
								tokenMin); else mk(EBlock(exprs), pmin(exprs[0]), pmax(exprs[exprs.length - 1]));
						case TBrClose:
							break;
						default:
							unexpected(tk);
							break;
					}
				}
				mk(ESwitch(parentExpr, cases, def), p1, tokenMax);
			case "import":
				var path = [getIdent()];
				var asStr:String = null;
				var star:Bool = false;
				
				while (true)
				{
					var t = token();
					if (t != TDot)
					{
						push(t);
						break;
					}
					t = token();
					switch (t)
					{
						case TOp("*"): star = true;
						case TId(id): path.push(id);
						default: unexpected(t);
					}
				}
				
				final asErr = " -> " + path.join(".") + " as " + asStr;
				
				if (maybe(TId("as")))
				{
					asStr = getIdent();
					final uppercased:Bool = asStr.charAt(0) == asStr.charAt(0).toUpperCase();
					if (asStr == null || asStr == "null" || asStr == "") unexpected(TId("as"));
					if (!uppercased) error(ECustom("Import aliases must begin with an uppercase letter." + asErr), readPos, readPos);
				}
				// trace(asStr);
				/*
					if (token() != TSemicolon) {
						error(ECustom("Missing semicolon at the end of a \"import\" declaration. -> "+asErr), readPos, readPos);
						null;
					}
				 */
				mk(EImport(path.join('.'), asStr));
				
			case "enum":
				var name = getIdent();
				
				ensure(TBrOpen);
				
				var fields = [];
				
				var currentName = "";
				var currentArgs:Array<Argument> = null;
				
				while (true)
				{
					var tk = token();
					switch (tk)
					{
						case TBrClose:
							break;
						case TSemicolon | TComma:
							if (currentName == "") continue;
							
							if (currentArgs != null && currentArgs.length > 0)
							{
								fields.push(EnumType.EConstructor(currentName, currentArgs));
								currentArgs = null;
							}
							else
							{
								fields.push(EnumType.ESimple(currentName));
							}
							currentName = "";
						case TPOpen:
							if (currentArgs != null)
							{
								error(ECustom("Cannot have multiple argument lists in one enum constructor"), tokenMin, tokenMax);
								break;
							}
							currentArgs = parseFunctionArgs();
						default:
							if (currentName != "")
							{
								error(ECustom("Expected comma or semicolon"), tokenMin, tokenMax);
								break;
							}
							var name = extractIdent(tk);
							currentName = name;
					}
				}
				
				mk(EEnum(name, fields));
			case "typedef":
				// typedef Name = Type;
				
				/*
					Ignore parsing if its, typedef Name = {
						> Person
						var name:String;
						var age:Int;
					}

					If the value is a class then it will be parsed as a EVar(Name, value);
				 */
				
				var name = getIdent();
				
				ensureToken(TOp("="));
				
				var t = parseType();
				
				switch (t)
				{
					case CTAnon(_) | CTExtend(_) | CTIntersection(_) | CTFun(_):
						mk(EIgnore(true));
					case CTPath(tp):
						var path = tp.pack.concat([tp.name]);
						var params = tp.params;
						if (params != null && params.length > 1) error(ECustom("Typedefs can't have parameters"), tokenMin, tokenMax);
						
						if (path.length == 0) error(ECustom("Typedefs can't be empty"), tokenMin, tokenMax);
						
						{
							var className = path.join(".");
							var cl = Tools.getClass(className);
							if (cl != null)
							{
								return mk(EVar(name, null, mk(EDirectValue(cl))));
							}
						}
						
						var expr = mk(EIdent(path.shift()));
						while (path.length > 0)
						{
							expr = mk(EField(expr, path.shift(), false));
						}
						
						// todo? add import to the beginning of the file?
						mk(EVar(name, null, expr));
					default:
						error(ECustom("Typedef, unknown type " + t), tokenMin, tokenMax);
						null;
				}
				
			case "using":
				var path = parsePath();
				mk(EUsing(path.join(".")));
			case "package":
				// ignore package
				var tk = token();
				push(tk);
				packageName = "";
				if (tk == TSemicolon) return mk(EIgnore(false));
				
				var path = parsePath();
				// mk(EPackage(path.join(".")));
				packageName = path.join(".");
				mk(EIgnore(false));
			case "public":
				final e = parseExpr();
				
				switch (e.expr())
				{
					case EVar(name, _), EFunction(_, _, name) if (name != null):
						mk(EMeta(':sharable', [], e), tokenMin, tokenMax);
					default:
						unexpected(TId(id));
				}
			default:
				null;
		}
	}
}
