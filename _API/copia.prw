	Local aTabelas := {}
	Local aField1 := {}
	Local aField2 := {}

aTabelas := {'tabela1','tabela2','tabela3', 'tabela4'}
aField1 := {'SRA.RA_CC','SQB.QB_XDEPTO','SRA.RA_CODFUNC', 'RA_MAT'}
aField2 := {'CTT.CTT_DESC01','ZA8.ZA8_DESCRI','SRJ.RJ_DESC', 'RA_NOME'}
aField3 := {'custo','departamentos','funcoes', 'funcionarios'}

For i = 1 To Len(aTabelas)

	cQuery := " SELECT "+aField1[i]+" CODIGO , "+aField2[i]+" DECRICAO, COUNT(*) AS TT " + CRLF

	If(i == 1)

		If(Empty(oJson["codDep"]))
			cQuery += " ,(SELECT "+cMes+" FROM ZA7020 ZA7 WHERE  D_E_L_E_T_ = '' AND ZA7_CCUST = "+aField1[i]+") AS ORCADO_CC"
		Else
			cQuery += " ,(SELECT "+cMes+" FROM ZA7020 ZA7 WHERE  D_E_L_E_T_ = '' AND ZA7_CCUST = "+aField1[i]+" ZA7_CDEPTO = '"+oJson["codDep"][1]+"' ) AS ORCADO_CC"
		EndIf

	EndIf

	If(i == 2)

		cQuery += " ,(SELECT "+cMes+" FROM ZA7020 ZA7 WHERE  D_E_L_E_T_ = '' AND ZA7_CDEPTO = "+aField1[i]+") AS ORCADO_DPTO " + CRLF

	EndIf

	If(i == 3 )

		cQuery += " ,(SELECT "+cMes+" TT FROM ZA7020 ZA7 WHERE  D_E_L_E_T_ = '' AND ZA7_CFUNC = "+aField1[i]+") AS ORCADO_FUNC " + CRLF

	EndIf

	cQuery += " FROM " + RetSqlName("SRA") + " SRA " + CRLF
	cQuery += " INNER JOIN " + RetSqlName("CTT") + " CTT ON CTT.D_E_L_E_T_ = '' AND CTT.CTT_CUSTO = SRA.RA_CC" + CRLF
	cQuery += " INNER JOIN " + RetSqlName("SQB") + " SQB ON SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO" + CRLF

	If(!Empty(oJson["codDir"]))
		cQuery += " AND SQB.QB_XDIRET IN " + formatIn(ArrTokStr(oJson["codDir"]), "|") + CRLF
	EndIf

	If(!Empty(oJson["codArea"]))
		cQuery += " AND SQB.QB_XAREA IN " + formatIn(ArrTokStr(oJson["codArea"]), "|") + CRLF
	EndIf

	If(!Empty(oJson["codDep"]))
		cQuery += " AND SQB.QB_XDEPTO IN " + formatIn(ArrTokStr(oJson["codDep"]), "|") + CRLF
	EndIf

	cQuery += " INNER JOIN " + RetSqlName("ZA8") + " ZA8 ON ZA8.D_E_L_E_T_ = '' AND ZA8.ZA8_CLASSI = '1' AND ZA8.ZA8_CODIGO = SQB.QB_XDEPTO " + CRLF
	cQuery += " INNER JOIN " + RetSqlName("SRJ") + " SRJ ON SRJ.D_E_L_E_T_ = '' AND SRJ.RJ_FUNCAO = SRA.RA_CODFUNC" + CRLF
	cQuery += " WHERE SRA.D_E_L_E_T_ = '' " + CRLF

	If(!Empty(oJson["codFunc"]))
		cQuery += " AND SRA.RA_CODFUNC IN " + formatIn(ArrTokStr(oJson["codFunc"]), "|") + CRLF
	EndIf

	If(!Empty(oJson["codCusto"]))
		cQuery += " AND SRA.RA_CC IN " + formatIn(ArrTokStr(oJson["codCusto"]), "|") + CRLF
	EndIf

	cQuery += " GROUP BY "+aField1[i]+" , "+aField2[i]+" " + CRLF
	cQuery += " ORDER BY "+aField1[i]+" " + CRLF

	Conout(cQuery)

	cAliasTop := MpSysOpenQuery(cQuery)

	nCont := 1
	cCusto := ''
	nOrcado := 0

	While !(cAliasTop)->(EoF())

		oRegistro := JsonObject():New()
		oRegistro['codigo'] := AllTrim((cAliasTop)->CODIGO)
		oRegistro[aField3[i]] := EncodeUTF8(AllTrim((cAliasTop)->DECRICAO))

		If(i < 4)

			If(i == 1)
				oRegistro['orc'] = ""
				jFuncionarios := infoFunc( (cAliasTop)->CODIGO, "", "", "", "", oJson["dataIni"])
				oRegistro['orc'] := cvaltochar((cAliasTop)->ORCADO_CC)
				nOrcado := (cAliasTop)->ORCADO_CC
			EndIf

			cCusto := (cAliasTop)->CODIGO

			If(i == 2)
				oRegistro['orc'] = ""
				jFuncionarios := infoFunc(cCusto, "", "", (cAliasTop)->CODIGO, "", oJson["dataIni"])
				oRegistro['orc'] := cvaltochar((cAliasTop)->ORCADO_DPTO)
				nOrcado := (cAliasTop)->ORCADO_DPTO
			EndIf

			If(i == 3)
				oRegistro['orc'] = ""
				jFuncionarios := infoFunc(cCusto, "", "", "", (cAliasTop)->CODIGO, oJson["dataIni"])
				oRegistro['orc'] := cvaltochar((cAliasTop)->ORCADO_FUNC)
				nOrcado := (cAliasTop)->ORCADO_FUNC
			EndIf

			oRegistro['real'] := cvaltochar((cAliasTop)->TT - (jFuncionarios['Ferias'][1] + jFuncionarios['Afastamento'][1] + jFuncionarios['Atestado'][1]))

			oRegistro['delta'] := cvaltochar(nOrcado - ((cAliasTop)->TT - (jFuncionarios['Ferias'][1] + jFuncionarios['Afastamento'][1] + jFuncionarios['Atestado'][1])))

		EndIf

		If Empty(jResponse[aTabelas[i]])
			jResponse[aTabelas[i]] := {}
		EndIf

		aAdd(jResponse[aTabelas[i]], oRegistro)

		(cAliasTop)->(DbSkip())

		nCont++

	EndDo

	(cAliasTop)->(DbCloseArea())

Next i
