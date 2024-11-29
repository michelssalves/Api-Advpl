#INCLUDE 'totvs.ch'
#INCLUDE 'restful.ch'
#INCLUDE "topconn.ch"

WSRESTFUL zWSDashRh DESCRIPTION 'WebService Dashboard'

	WSMETHOD POST TABELA DESCRIPTION 'Tabela' WSSYNTAX '/zWSDashRh/get_table' PATH 'get_table' PRODUCES APPLICATION_JSON
	WSMETHOD POST ALLCC DESCRIPTION 'Lista de Custos' WSSYNTAX '/zWSDashRh/get_custo' PATH 'get_custo' PRODUCES APPLICATION_JSON
	WSMETHOD POST ALLFUNCOES DESCRIPTION 'Lista de Funcoes' WSSYNTAX '/zWSDashRh/get_funcoes' PATH 'get_funcoes' PRODUCES APPLICATION_JSON
	WSMETHOD POST ALLDIRETORES DESCRIPTION 'Array de Diretores' WSSYNTAX '/zWSDashRh/get_diretores' PATH 'get_diretores' PRODUCES APPLICATION_JSON
	WSMETHOD POST ALLAREAS DESCRIPTION 'Array de Areas' WSSYNTAX '/zWSDashRh/get_areas' PATH 'get_areas' PRODUCES APPLICATION_JSON
	WSMETHOD POST ALLDEPTO DESCRIPTION 'Array de Departamentos' WSSYNTAX '/zWSDashRh/get_depto' PATH 'get_depto' PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD POST TABELA WSSERVICE zWSDashRh

	Local lRet       := .T.
	Local cAliasTop := ''
	Local jResponse  := JsonObject():New()
	Local jFuncionarios  := JsonObject():New()
	Local cQuery := ''
	Local i
	Local y
	Local cMes := ''
	Local cBody       := ''
	Local oJson     := NIL
	Local nOrcado := 0
	Local nReal := 0
	Local nOutros := 0
	Local cCusto := ''
	Local aCusto := {}

	cBody := ::GetContent()
	::SetContentType("application/json")
	oJson := JsonObject():new()
	oJson:fromJson(cBody)

	If(!Empty(oJson["dataIni"]))

		If(!Empty(oJson["codCusto"]) .Or. !Empty(oJson["codDir"]) .Or.  !Empty(oJson["codArea"]) .Or.  !Empty(oJson["codDep"]))

			For i = 1 To Len(oJson["codCusto"])

				If (checkDpto(oJson["codCusto"][i] ,oJson["codDep"][i] ))
					CTT->( dbSetOrder(1) )
					CTT->( dbSeek( xFilial("CTT") + oJson["codCusto"][i] ) )

					oRegistro := JsonObject():New()

					oRegistro['codigo'] := AllTrim(CTT->CTT_CUSTO)
					oRegistro['custo'] := EncodeUTF8(AllTrim(CTT->CTT_DESC01))

					nReal := 0
					nOrcado := 0



					If (!Empty(oJson["dataIni"]))

						nMes := Val(SubStr(oJson["dataIni"], 5, 2))
						cMes := AllTrim(Str(nMes))
						cMes := "SUM(ZA7_MES"+cValToChar(cMes)+") ORCADO_CC"

						nTam := iif(Len(oJson["codDep"]) > 0, Len(oJson["codDep"]), 1)

						For y = 1 To nTam

							cQuery := "SELECT "+cMes+" FROM ZA7020 ZA7 WHERE  D_E_L_E_T_ = '' AND ZA7_CCUST = '"+oJson["codCusto"][i]+"' "

							If(!Empty(oJson["codDep"]))



								If(!Empty(oJson["codFunc"]))
									nReal += countAtivos(oJson["codCusto"][i], oJson["codDep"][i], oJson["codFunc"][i])
								Else
									nReal += countAtivos(oJson["codCusto"][i], oJson["codDep"][i], "")
								EndIf

							Else
								nReal += countAtivos(oJson["codCusto"][i], "")
							EndIf


							If(!Empty(oJson["codDep"]))
								cQuery += "AND ZA7_CDEPTO = '"+oJson["codDep"][i]+"' "
							EndIf

							cAliasTop := MpSysOpenQuery(cQuery)
							nOrcado += (cAliasTop)->ORCADO_CC

							(cAliasTop)->(DbCloseArea())



						Next y

					EndIf
				EndIf



				oRegistro['orc'] := cvaltochar(nOrcado)
				oRegistro['real'] := cvaltochar(nReal)

				If Empty(jResponse['tabela1'])
					jResponse['tabela1'] := {}
				EndIf

				aAdd(jResponse['tabela1'], oRegistro)

			Next i

			cAliasTop := listDepartamentos(oJson["codCusto"], oJson["codDep"], oJson["codFunc"])

			While !(cAliasTop)->(EoF())

				oRegistro := JsonObject():New()

				oRegistro['codigo'] := (cAliasTop)->QB_XDEPTO
				oRegistro['departamento'] := (cAliasTop)->ZA8_DESCRI

				oRegistro['orc'] := cvaltochar(countOrcado((cAliasTop)->RA_CC, (cAliasTop)->QB_XDEPTO, "", oJson["dataIni"]))

				oRegistro['real'] := cvaltochar(countAtivos((cAliasTop)->RA_CC, (cAliasTop)->QB_XDEPTO))

				If Empty(jResponse['tabela2'])
					jResponse['tabela2'] := {}
				EndIf

				aAdd(jResponse['tabela2'], oRegistro)

				(cAliasTop)->(DbSkip())

			EndDo

			(cAliasTop)->(DbCloseArea())

			cAliasTop := listFuncoes(oJson["codCusto"], oJson["codDep"], oJson["codFunc"])

			While !(cAliasTop)->(EoF())

				oRegistro := JsonObject():New()

				oRegistro['codigo'] := (cAliasTop)->RA_CODFUNC
				oRegistro['funcao'] := (cAliasTop)->RJ_DESC

				oRegistro['orc'] := cvaltochar(countOrcado((cAliasTop)->RA_CC, "", (cAliasTop)->RA_CODFUNC, oJson["dataIni"]))

				oRegistro['real'] := cvaltochar(countAtivos((cAliasTop)->RA_CC, (cAliasTop)->RA_CODFUNC))

				If Empty(jResponse['tabela3'])
					jResponse['tabela3'] := {}
				EndIf

				aAdd(jResponse['tabela3'], oRegistro)

				(cAliasTop)->(DbSkip())

			EndDo

			(cAliasTop)->(DbCloseArea())


			Self:SetContentType('application/json')
			Self:SetResponse(jResponse:toJSON())

		EndIf
	EndIf

Return lRet

Static Function checkDpto(codCusto, codDpto)

	Local lRet := .F.
	Local cQuery := ''
	Local cAliasTop := ''
	Local nContagem := 0

	cQuery := " SELECT COUNT(*) TOTAL FROM " + RetSqlName("ZA7") + " ZA7 + CRLF
	cQuery += " WHERE D_E_L_E_T_ = '' "
	cQuery += " AND ZA7_CCUST = '"+codCusto+"' "
	cQuery += " AND ZA7_CDEPTO = '"+codDpto+"' "

	cAliasTop := MpSysOpenQuery(cQuery)

	nContagem += (cAliasTop)->TOTAL

	If (nContagem > 0 )
		lRet = .T.
	EndIf

	(cAliasTop)->(DbCloseArea())

Return lRet

Static Function countOrcado(codCusto, codDpto, codFunc, cData)

	Local cQuery := ''
	Local cAliasTop := ''
	Local nContagem := 0
	Local cMes := ''
	Local nMes := 1

	nMes := Val(SubStr(cData, 5, 2))
	cMes := AllTrim(Str(nMes))
	cMes := "SUM(ZA7_MES"+cValToChar(cMes)+") TOTAL"

	cQuery := " SELECT "+cMes+" FROM " + RetSqlName("ZA7") + " ZA7  " + CRLF

	cQuery += " WHERE  D_E_L_E_T_ = '' " + CRLF

	If(!Empty(codCusto))

		cQuery += " AND ZA7_CCUST = '"+codCusto+"' " + CRLF

	EndIf

	If(!Empty(codDpto))

		cQuery += " AND ZA7_CDEPTO = '"+codDpto+"' " + CRLF

	EndIf

	If(!Empty(codFunc))

		cQuery += " AND ZA7_CFUNC = '"+codFunc+"' " + CRLF

	EndIf

	Conout(cQuery)

	cAliasTop := MpSysOpenQuery(cQuery)

	nContagem += (cAliasTop)->TOTAL

	(cAliasTop)->(DbCloseArea())

Return nContagem

Static Function countAtivos(codCusto, codDpto, codFunc)

	Local cQuery := ''
	Local cAliasTop := ''
	Local nContagem := 0

	cQuery := " SELECT COUNT(*) TOTAL " + CRLF

	cQuery += " FROM " + RetSqlName("SRA") +" SRA  " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("CTT") + " CTT ON CTT.D_E_L_E_T_ = '' AND CTT.CTT_CUSTO = SRA.RA_CC " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("SQB") + " SQB ON SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("ZA8") + " ZA8 ON ZA8.D_E_L_E_T_ = '' AND ZA8.ZA8_CLASSI = '1' AND ZA8.ZA8_CODIGO = SQB.QB_XDEPTO  " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("SRJ") + " SRJ ON SRJ.D_E_L_E_T_ = '' AND SRJ.RJ_FUNCAO = SRA.RA_CODFUNC " + CRLF

	cQuery += "  WHERE SRA.D_E_L_E_T_ = ''  " + CRLF

	If(!Empty(codCusto))

		cQuery += "   AND SRA.RA_CC = ('"+codCusto+"')  " + CRLF

	EndIf

	If(!Empty(codDpto))

		cQuery += "   AND SQB.QB_XDEPTO = ('"+codDpto+"')  " + CRLF

	EndIf

	If(!Empty(codFunc))

		cQuery += "   AND SRA.RA_CODFUNC = ('"+codFunc+"')  " + CRLF

	EndIf


	cAliasTop := MpSysOpenQuery(cQuery)

	nContagem += (cAliasTop)->TOTAL

	(cAliasTop)->(DbCloseArea())

Return nContagem

Static Function listDepartamentos(codCusto, codDpto, codFunc)

	Local cQuery := ''
	Local cAliasTop := ''
	Local cFilFunc := ''

	If(!Empty(codFunc))

		cFilFunc += ", SRA.RA_CODFUNC"

	EndIf

	cQuery := " SELECT SQB.QB_XDEPTO, ZA8.ZA8_DESCRI, SRA.RA_CC "+cFilFunc+"" + CRLF

	cQuery += " FROM " + RetSqlName("SRA") +" SRA  " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("CTT") + " CTT ON CTT.D_E_L_E_T_ = '' AND CTT.CTT_CUSTO = SRA.RA_CC " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("SQB") + " SQB ON SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("ZA8") + " ZA8 ON ZA8.D_E_L_E_T_ = '' AND ZA8.ZA8_CLASSI = '1' AND ZA8.ZA8_CODIGO = SQB.QB_XDEPTO  " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("SRJ") + " SRJ ON SRJ.D_E_L_E_T_ = '' AND SRJ.RJ_FUNCAO = SRA.RA_CODFUNC " + CRLF

	cQuery += "  WHERE SRA.D_E_L_E_T_ = ''  " + CRLF

	If(!Empty(codCusto))

		cQuery += "   AND SRA.RA_CC IN " + formatIn(ArrTokStr(codCusto), "|") + CRLF

	EndIf

	If(!Empty(codDpto))

		cQuery += "   AND SQB.QB_XDEPTO IN " + formatIn(ArrTokStr(codDpto), "|") + CRLF

	EndIf

	// If(!Empty(codFunc))

	// 	cQuery += "   AND SRA.RA_CODFUNC = ('"+codFunc+"')  " + CRLF

	// EndIf

	cQuery += "  GROUP BY SQB.QB_XDEPTO, ZA8.ZA8_DESCRI, SRA.RA_CC  "+cFilFunc+" " + CRLF
	cQuery += "  ORDER BY SQB.QB_XDEPTO " + CRLF

	Conout(cQuery)

	cAliasTop := MpSysOpenQuery(cQuery)

Return cAliasTop

Static Function listFuncoes(codCusto, codDpto, codFunc)

	Local cQuery := ''
	Local cAliasTop := ''
	Local cFilFunc := ''

	cQuery := " SELECT SRA.RA_CODFUNC, SRJ.RJ_DESC, SRA.RA_CC "+cFilFunc+"" + CRLF

	cQuery += " FROM " + RetSqlName("SRA") +" SRA  " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("CTT") + " CTT ON CTT.D_E_L_E_T_ = '' AND CTT.CTT_CUSTO = SRA.RA_CC " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("SQB") + " SQB ON SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("ZA8") + " ZA8 ON ZA8.D_E_L_E_T_ = '' AND ZA8.ZA8_CLASSI = '1' AND ZA8.ZA8_CODIGO = SQB.QB_XDEPTO  " + CRLF

	cQuery += " INNER JOIN " + RetSqlName("SRJ") + " SRJ ON SRJ.D_E_L_E_T_ = '' AND SRJ.RJ_FUNCAO = SRA.RA_CODFUNC " + CRLF

	cQuery += "  WHERE SRA.D_E_L_E_T_ = ''  " + CRLF

	If(!Empty(codCusto))

		cQuery += "   AND SRA.RA_CC IN " + formatIn(ArrTokStr(codCusto), "|") + CRLF

	EndIf

	If(!Empty(codFunc))

		cQuery += "   AND SRA.RA_CODFUNC IN " + formatIn(ArrTokStr(codFunc), "|") + CRLF

	EndIf

	cQuery += "  GROUP BY SRA.RA_CODFUNC, SRJ.RJ_DESC, SRA.RA_CC " + CRLF
	cQuery += "  ORDER BY SRA.RA_CODFUNC " + CRLF

	Conout(cQuery)

	cAliasTop := MpSysOpenQuery(cQuery)

Return cAliasTop

// Static Function listarFuncoes(codCusto, codDpto, codFunc)

// 	Local cQuery := ''
// 	Local cAliasTop := ''
// 	Local cFilFunc := ''

// 	If(!Empty(codFunc))

// 		cFilFunc += ", SRA.RA_CODFUNC"

// 	EndIf

// 	cQuery := " SELECT SQB.QB_XDEPTO, ZA8.ZA8_DESCRI, SRA.RA_CC "+cFilFunc+"" + CRLF

// 	cQuery += " FROM " + RetSqlName("SRA") +" SRA  " + CRLF

// 	cQuery += " INNER JOIN " + RetSqlName("CTT") + " CTT ON CTT.D_E_L_E_T_ = '' AND CTT.CTT_CUSTO = SRA.RA_CC " + CRLF

// 	cQuery += " INNER JOIN " + RetSqlName("SQB") + " SQB ON SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO " + CRLF

// 	cQuery += " INNER JOIN " + RetSqlName("ZA8") + " ZA8 ON ZA8.D_E_L_E_T_ = '' AND ZA8.ZA8_CLASSI = '1' AND ZA8.ZA8_CODIGO = SQB.QB_XDEPTO  " + CRLF

// 	cQuery += " INNER JOIN " + RetSqlName("SRJ") + " SRJ ON SRJ.D_E_L_E_T_ = '' AND SRJ.RJ_FUNCAO = SRA.RA_CODFUNC " + CRLF

// 	cQuery += "  WHERE SRA.D_E_L_E_T_ = ''  " + CRLF

// 	If(!Empty(codCusto))

// 		cQuery += "   AND SRA.RA_CC IN " + formatIn(ArrTokStr(codCusto), "|") + CRLF

// 	EndIf

// 	If(!Empty(codDpto))

// 		cQuery += "   AND SQB.QB_XDEPTO IN " + formatIn(ArrTokStr(codDpto), "|") + CRLF

// 	EndIf

// 	If(!Empty(codFunc))

// 		cQuery += "   AND SRA.RA_CODFUNC = ('"+codFunc+"')  " + CRLF

// 	EndIf

// 	cQuery += "  GROUP BY SQB.QB_XDEPTO, ZA8.ZA8_DESCRI, SRA.RA_CC, SRA.RA_CODFUNC    " + CRLF
// 	cQuery += "  ORDER BY SQB.QB_XDEPTO " + CRLF

// 	Conout(cQuery)

// 	cAliasTop := MpSysOpenQuery(cQuery)

// Return cAliasTop

WSMETHOD POST ALLCC WSSERVICE zWSDashRh

	Local lRet       := .T.
	Local cAliasTop := ''
	Local jResponse  := JsonObject():New()
	Local cQuery := ''
	Local cBody       := ''
	Local oJson     := NIL

	cBody := ::GetContent()
	::SetContentType("application/json")
	oJson := JsonObject():new()
	oJson:fromJson(cBody)

	cQuery := " SELECT SRA.RA_CC , CTT.CTT_DESC01 FROM SRA020 SRA  " + CRLF
	cQuery += " INNER JOIN CTT020 CTT ON CTT.D_E_L_E_T_ = '' AND CTT.CTT_CUSTO = SRA.RA_CC" + CRLF
	cQuery += " INNER JOIN SQB020 SQB ON SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO" + CRLF

	If(!Empty(oJson["codDir"]))
		cQuery += " AND SQB.QB_XDIRET IN " + formatIn(ArrTokStr(oJson["codDir"]), "|") + CRLF
	EndIf
	If(!Empty(oJson["codArea"]))
		cQuery += " AND SQB.QB_XAREA IN " + formatIn(ArrTokStr(oJson["codArea"]), "|") + CRLF
	EndIf
	If(!Empty(oJson["codDep"]))
		cQuery += " AND SQB.QB_XDEPTO IN " + formatIn(ArrTokStr(oJson["codDep"]), "|") + CRLF
	EndIf

	cQuery += " INNER JOIN SRJ020 SRJ ON SRJ.D_E_L_E_T_ = '' AND SRJ.RJ_FUNCAO = SRA.RA_CODFUNC" + CRLF
	cQuery += " WHERE SRA.D_E_L_E_T_ = '' " + CRLF

	If(!Empty(oJson["codFunc"]))
		cQuery += " AND SRA.RA_CODFUNC IN " + formatIn(ArrTokStr(oJson["codFunc"]), "|") + CRLF
	EndIf
	If(!Empty(oJson["codCusto"]))
		cQuery += " AND SRA.RA_CC IN " + formatIn(ArrTokStr(oJson["codCusto"]), "|") + CRLF
	EndIf

	cQuery += " GROUP BY SRA.RA_CC , CTT.CTT_DESC01" + CRLF
	cQuery += " ORDER BY SRA.RA_CC " + CRLF

	cAliasTop := MpSysOpenQuery( cQuery )

	jResponse['objects'] := {}


	While ! (cAliasTop)->(EoF())

		oRegistro := JsonObject():New()
		oRegistro['value'] := AllTrim((cAliasTop)->RA_CC)
		oRegistro['label'] := AllTrim((cAliasTop)->RA_CC) + " - " + EncodeUTF8(AllTrim((cAliasTop)->CTT_DESC01))
		aAdd(jResponse['objects'], oRegistro)
		(cAliasTop)->(DbSkip())

	EndDo

	(cAliasTop)->(DbCloseArea())

	Self:SetContentType('application/json')
	Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD POST ALLFUNCOES WSSERVICE zWSDashRh

	Local lRet       := .T.
	Local cAliasTop := ''
	Local jResponse  := JsonObject():New()
	Local cQuery := ''
	Local cBody       := ''
	Local oJson     := NIL

	cBody := ::GetContent()
	::SetContentType("application/json")
	oJson := JsonObject():new()
	oJson:fromJson(cBody)

	cQuery := " SELECT SRA.RA_CODFUNC , SRJ.RJ_DESC FROM SRA020 SRA  " + CRLF
	cQuery += " INNER JOIN SQB020 SQB ON SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO" + CRLF

	If(!Empty(oJson["codDir"]))
		cQuery += " AND SQB.QB_XDIRET IN " + formatIn(ArrTokStr(oJson["codDir"]), "|") + CRLF
	EndIf
	If(!Empty(oJson["codArea"]))
		cQuery += " AND SQB.QB_XAREA IN " + formatIn(ArrTokStr(oJson["codArea"]), "|") + CRLF
	EndIf
	If(!Empty(oJson["codDep"]))
		cQuery += " AND SQB.QB_XDEPTO IN " + formatIn(ArrTokStr(oJson["codDep"]), "|") + CRLF
	EndIf

	cQuery += " INNER JOIN SRJ020 SRJ ON SRJ.D_E_L_E_T_ = '' AND SRJ.RJ_FUNCAO = SRA.RA_CODFUNC" + CRLF
	cQuery += " WHERE SRA.D_E_L_E_T_ = '' " + CRLF

	If(!Empty(oJson["codCusto"]))
		cQuery += " AND SRA.RA_CC IN " + formatIn(ArrTokStr(oJson["codCusto"]), "|") + CRLF
	EndIf

	cQuery += " GROUP BY SRA.RA_CODFUNC , SRJ.RJ_DESC" + CRLF
	cQuery += " ORDER BY SRA.RA_CODFUNC " + CRLF

	cAliasTop := MpSysOpenQuery( cQuery )

	jResponse['objects'] := {}

	While ! (cAliasTop)->(EoF())

		oRegistro := JsonObject():New()
		oRegistro['value'] := AllTrim((cAliasTop)->RA_CODFUNC )
		oRegistro['label'] := AllTrim((cAliasTop)->RA_CODFUNC ) + " - " + EncodeUTF8(AllTrim((cAliasTop)->RJ_DESC))
		aAdd(jResponse['objects'], oRegistro)
		(cAliasTop)->(DbSkip())

	EndDo

	(cAliasTop)->(DbCloseArea())

	Self:SetContentType('application/json')
	Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD POST ALLDIRETORES WSSERVICE zWSDashRh

	Local lRet      := .T.
	Local cAliasTop := ''
	Local jResponse  := JsonObject():New()
	Local cQuery := ''
	Local cBody       := ''
	Local oJson     := NIL

	cBody := ::GetContent()
	::SetContentType("application/json")
	oJson := JsonObject():new()
	oJson:fromJson(cBody)

	jResponse['objects'] := JsonObject():New()

	cQuery := " SELECT SQB.QB_XDIRET, ZA8.ZA8_DESCRI FROM SRA020 SRA  " + CRLF
	cQuery += " INNER JOIN CTT020 CTT ON CTT.D_E_L_E_T_ = '' AND CTT.CTT_CUSTO = SRA.RA_CC  " + CRLF

	cQuery += " INNER JOIN SQB020 SQB ON  SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO  " + CRLF
	If(!Empty(oJson["codArea"]))
		cQuery += " AND SQB.QB_XAREA IN " + formatIn(ArrTokStr(oJson["codArea"]), "|")+ CRLF
	EndIf
	If(!Empty(oJson["codDep"]))
		cQuery += " AND SQB.QB_XDEPTO IN " + formatIn(ArrTokStr(oJson["codDep"]), "|") + CRLF
	EndIf

	cQuery += " INNER JOIN ZA8020 ZA8 ON ZA8.D_E_L_E_T_ = '' AND ZA8.ZA8_CLASSI = '3' AND ZA8.ZA8_CODIGO = SQB.QB_XDIRET " + CRLF
	cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRA.RA_SITFOLH != 'D'  " + CRLF
	If(!Empty(oJson["codCusto"]))
		cQuery += " AND SRA.RA_CC IN " + formatIn(ArrTokStr(oJson["codCusto"]), "|") + CRLF
	EndIf
	If(!Empty(oJson["codFunc"]))
		cQuery += " AND SRA.RA_CODFUNC IN " + formatIn(ArrTokStr(oJson["codFunc"]), "|") + CRLF
	EndIf

	cQuery += " GROUP BY SQB.QB_XDIRET, ZA8.ZA8_DESCRI " + CRLF
	cQuery += " ORDER BY SQB.QB_XDIRET " + CRLF

	cAliasTop := MpSysOpenQuery(cQuery)

	jResponse['objects']['diretores'] := {}

	While ! (cAliasTop)->(EoF())

		oRegistro := JsonObject():New()
		oRegistro['value'] := AllTrim((cAliasTop)->QB_XDIRET)
		oRegistro['label'] := AllTrim((cAliasTop)->QB_XDIRET) + " - " + EncodeUTF8(AllTrim((cAliasTop)->ZA8_DESCRI))

		aAdd(jResponse['objects']['diretores'], oRegistro)

		(cAliasTop)->(DbSkip())
	EndDo

	(cAliasTop)->(DbCloseArea())

	Self:SetContentType('application/json')
	Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD POST ALLAREAS WSSERVICE zWSDashRh

	Local lRet      := .T.
	Local cAliasTop := ''
	Local jResponse  := JsonObject():New()
	Local cQuery := ''
	Local cBody       := ''
	Local oJson     := NIL

	cBody := ::GetContent()
	::SetContentType("application/json")
	oJson := JsonObject():new()
	oJson:fromJson(cBody)

	jResponse['objects'] := JsonObject():New()

	cQuery := " SELECT SQB.QB_XAREA, ZA8.ZA8_DESCRI FROM SRA020 SRA  " + CRLF
	cQuery += " INNER JOIN CTT020 CTT ON CTT.D_E_L_E_T_ = '' AND CTT.CTT_CUSTO = SRA.RA_CC  " + CRLF
	cQuery += " INNER JOIN SQB020 SQB ON  SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO  " + CRLF

	If(!Empty(oJson["codDir"]))
		cQuery += " AND SQB.QB_XDIRET IN " + formatIn(ArrTokStr(oJson["codDir"]), "|") + CRLF
	EndIf
	If(!Empty(oJson["codDep"]))
		cQuery += " AND SQB.QB_XDEPTO IN " + formatIn(ArrTokStr(oJson["codDep"]), "|") + CRLF
	EndIf

	cQuery += " INNER JOIN ZA8020 ZA8 ON ZA8.D_E_L_E_T_ = '' AND ZA8.ZA8_CLASSI = '2' AND ZA8.ZA8_CODIGO = SQB.QB_XAREA " + CRLF
	cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRA.RA_SITFOLH != 'D'  " + CRLF

	If(!Empty(oJson["codCusto"]))
		cQuery += " AND SRA.RA_CC IN " + formatIn(ArrTokStr(oJson["codCusto"]), "|") + CRLF
	EndIf
	If(!Empty(oJson["codFunc"]))
		cQuery += " AND SRA.RA_CODFUNC IN " + formatIn(ArrTokStr(oJson["codFunc"]), "|") + CRLF
	EndIf

	cQuery += " GROUP BY SQB.QB_XAREA, ZA8.ZA8_DESCRI " + CRLF
	cQuery += " ORDER BY SQB.QB_XAREA " + CRLF

	cAliasTop := MpSysOpenQuery(cQuery)

	jResponse['objects']['areas'] := {}

	While ! (cAliasTop)->(EoF())

		oRegistro := JsonObject():New()
		oRegistro['value'] := AllTrim((cAliasTop)->QB_XAREA)
		oRegistro['label'] := AllTrim((cAliasTop)->QB_XAREA) + " - " + EncodeUTF8(AllTrim((cAliasTop)->ZA8_DESCRI))

		aAdd(jResponse['objects']['areas'], oRegistro)

		(cAliasTop)->(DbSkip())
	EndDo

	(cAliasTop)->(DbCloseArea())

	Self:SetContentType('application/json')
	Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD POST ALLDEPTO WSSERVICE zWSDashRh

	Local lRet      := .T.
	Local cAliasTop := ''
	Local jResponse  := JsonObject():New()
	Local cQuery := ''
	Local cBody       := ''
	Local oJson     := NIL

	cBody := ::GetContent()
	::SetContentType("application/json")
	oJson := JsonObject():new()
	oJson:fromJson(cBody)

	jResponse['objects'] := JsonObject():New()

	cQuery := " SELECT SQB.QB_XDEPTO, ZA8.ZA8_DESCRI FROM SRA020 SRA  " + CRLF
	cQuery += " INNER JOIN CTT020 CTT ON CTT.D_E_L_E_T_ = '' AND CTT.CTT_CUSTO = SRA.RA_CC  " + CRLF
	cQuery += " INNER JOIN SQB020 SQB ON  SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO  " + CRLF

	If(!Empty(oJson["codDir"]))
		cQuery += " AND SQB.QB_XDIRET IN " + formatIn(ArrTokStr(oJson["codDir"]), "|") + CRLF
	EndIf

	If(!Empty(oJson["codArea"]))
		cQuery += " AND SQB.QB_XAREA IN " + formatIn(ArrTokStr(oJson["codArea"]), "|") + CRLF
	EndIf

	cQuery += " INNER JOIN ZA8020 ZA8 ON ZA8.D_E_L_E_T_ = '' AND ZA8.ZA8_CLASSI = '1' AND ZA8.ZA8_CODIGO = SQB.QB_XDEPTO " + CRLF
	cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRA.RA_SITFOLH != 'D'  " + CRLF

	If(!Empty(oJson["codCusto"]))
		cQuery += " AND SRA.RA_CC IN " + formatIn(ArrTokStr(oJson["codCusto"]), "|") + CRLF
	EndIf

	If(!Empty(oJson["codFunc"]))
		cQuery += " AND SRA.RA_CODFUNC IN " + formatIn(ArrTokStr(oJson["codFunc"]), "|") + CRLF
	EndIf

	cQuery += " GROUP BY SQB.QB_XDEPTO, ZA8.ZA8_DESCRI " + CRLF
	cQuery += " ORDER BY SQB.QB_XDEPTO " + CRLF

	cAliasTop := MpSysOpenQuery(cQuery)

	jResponse['objects']['departamentos'] := {}

	While ! (cAliasTop)->(EoF())

		oRegistro := JsonObject():New()
		oRegistro['value'] := AllTrim((cAliasTop)->QB_XDEPTO)
		oRegistro['label'] := AllTrim((cAliasTop)->QB_XDEPTO) + " - " + EncodeUTF8(AllTrim((cAliasTop)->ZA8_DESCRI))

		aAdd(jResponse['objects']['departamentos'], oRegistro)

		(cAliasTop)->(DbSkip())
	EndDo

	(cAliasTop)->(DbCloseArea())

	Self:SetContentType('application/json')
	Self:SetResponse(jResponse:toJSON())

Return lRet

Static Function infoFunc(aCodCusto, aCodDir, aCodArea, aCodDep, aCodFunc, cDataIni)

	Local i
	Local aLabel :=  {'Ferias', 'Afastamento', 'Atestado'}
	Local jResponse  := JsonObject():New()

	If !Empty(aCodCusto)

		For i := 1 To 3

			cQuery := " SELECT " + CRLF
			cQuery += " '"+aLabel[i]+"' AS TIPO, " + CRLF
			cQuery += " COUNT(*) AS VALOR, " + CRLF
			cQuery += " CONCAT('"+aLabel[i]+": ', COUNT(*)) AS INFO" + CRLF
			cQuery += " FROM " + CRLF
			cQuery += " SR8020 SR8 " + CRLF
			cQuery += " INNER JOIN SRA020 SRA ON SRA.RA_SITFOLH != 'D' AND RA_MAT=R8_MAT " + CRLF

			If(!Empty(aCodFunc))
				cQuery += " AND SRA.RA_CODFUNC IN " + formatIn(ArrTokStr(aCodFunc), "|") + CRLF
			EndIf

			If (!Empty(aCodCusto))
				cFilCC := formatIn(ArrTokStr(aCodCusto), "|")
				cQuery += " AND SRA.RA_CC IN " + If(cFilCC == "('')", "('" + aCodCusto + "')", cFilCC) + CRLF
			EndIf
			cQuery += " INNER JOIN SQB020 SQB ON  SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO  " + CRLF

			If(!Empty(aCodDir))
				cQuery += " AND SQB.QB_XDIRET IN " + formatIn(ArrTokStr(aCodDir), "|") + CRLF
			EndIf

			If(!Empty(aCodArea))
				cQuery += " AND SQB.QB_XAREA IN " + formatIn(ArrTokStr(aCodArea), "|") + CRLF
			EndIf

			If(!Empty(aCodDep))
				cQuery += " AND SQB.QB_XDEPTO IN " + formatIn(ArrTokStr(aCodDep), "|") + CRLF
			EndIf

			cQuery += " INNER JOIN ZA8020 ZA8 ON ZA8.D_E_L_E_T_ = '' AND ZA8.ZA8_CLASSI = '1' AND ZA8.ZA8_CODIGO = SQB.QB_XDEPTO " + CRLF
			cQuery += " WHERE " + CRLF
			cQuery += " SR8.D_E_L_E_T_='' " + CRLF
			cQuery += " AND SR8.R8_FILIAL= '01' " + CRLF
			cQuery += " AND SR8.R8_DATA=( " + CRLF
			cQuery += "     SELECT " + CRLF
			cQuery += "         MAX(SR81.R8_DATA) " + CRLF
			cQuery += "     FROM " + CRLF
			cQuery += "         SR8020 SR81 " + CRLF
			cQuery += "     WHERE " + CRLF
			cQuery += "         SR81.D_E_L_E_T_='' " + CRLF
			cQuery += "         AND SR81.R8_FILIAL=SR8.R8_FILIAL " + CRLF
			cQuery += "         AND SR81.R8_MAT=SR8.R8_MAT " + CRLF
			cQuery += "         AND SR81.R8_DATA <= '"+cDataIni+"' " + CRLF
			cQuery += " )    " + CRLF
			cQuery += " AND EXISTS( " + CRLF
			cQuery += " SELECT 1 " + CRLF
			cQuery += " FROM RCM020 RCM " + CRLF
			cQuery += " WHERE RCM.D_E_L_E_T_= '' " + CRLF
			cQuery += " AND RCM.RCM_TIPO=SR8.R8_TIPOAFA  " + CRLF
			If(i = 1)
				cQuery += "AND RCM.RCM_TIPOAF='4') " + CRLF
			Else
				cQuery += "AND RCM.RCM_TIPOAF='1') " + CRLF
			Endif
			If(i = 2)
				cQuery += " AND ( " + CRLF
				cQuery += " (SR8.R8_DATAFIM='' AND DATEDIFF ( DAY , SR8.R8_DATAINI , '"+cDataIni+"') > 120) " + CRLF
				cQuery += " OR (SR8.R8_DATAFIM!='' AND DATEDIFF ( DAY , SR8.R8_DATAINI , SR8.R8_DATAFIM) > 120) " + CRLF
				cQuery += " ) " + CRLF
			Else
				cQuery += " AND ( '"+cDataIni+"' BETWEEN R8_DATAINI AND R8_DATAFIM OR R8_DATAFIM='' ) " + CRLF
				cQuery += " AND R8_DURACAO <= 120 " + CRLF
			Endif

			Conout(cQuery)

			cAliasTop := MpSysOpenQuery( cQuery )

			If Empty(jResponse[aLabel[i]])
				jResponse[aLabel[i]] := {}
			EndIf

			aAdd(jResponse[aLabel[i]], (cAliasTop)->VALOR)

		Next i

		(cAliasTop)->(DbCloseArea())
	EndIf

Return jResponse


