#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"
#Include "TOTVS.ch"

User Function relTest()

	RpcClearenv()
	RPCSetType(3)
	RpcSetEnv('02')

	U_ct2dados()

	RpcClearEnv()

Return
User Function ct2dados()

	Private cPerg    := "ZREPCT2"
	Private oReport  := nil
	Private oSection := nil

	Pergunte(cPerg, .F.)

	oReport := ReportDef(cPerg)
	oReport:nDevice := 4
	oReport:SetEnvironment(2)
	oReport:PrintDialog()

Return

Static Function ReportDef(cPerg)

	oReport := TReport():New("ZREPCT2", "Relatório da CT2.", cPerg , {|oReport| GerRelExe()}, "Este relatório imprime dados da CT2.")
	oReport:cFontBody := 'Courier New'
	oReport:nFontBody := 8

	oSection := TRSection():New(oReport, "Relatório da CT2", {},,,,,,.T.,,,,,,,,,,,,)

	TRCell():New(oSection,"NOME"        , nil, "Forn/Cliente"        ,"@!",10)
	TRCell():New(oSection,"CNPJ"        , nil, "CNPJ"        ,"@!",10)
	TRCell():New(oSection,"CODIGO"        , nil, "Código"        ,"@!",10)
	TRCell():New(oSection,"LOJA"        , nil, "Loja"        ,"@!",10)
	TRCell():New(oSection,"DATA"        , nil, "Data"        ,"@!", 8)
	TRCell():New(oSection,"HISTORICO"        , nil, "Histórico"        ,"@!",10)
	TRCell():New(oSection,"CREDITO"        , nil, "Credito"        ,"@!",10)
	TRCell():New(oSection,"DESC CREDITO"        , nil, "Desc. Credito"        ,"@!",10)
	TRCell():New(oSection,"DEBITO"        , nil, "Debito"        ,"@!",10)
	TRCell():New(oSection,"DESC DEBITO"        , nil, "Desc. Debito"        ,"@!",10)

Return(oReport)

Static Function GerRelExe()

	Local cAliasTop := ""
	Local cQuery	:= ""

	cDtAtual := DTOS(Date())

	cQuery := " SELECT " + CRLF
	cQuery += " IIF(A1_COD IS NULL,A2_NOME, A1_NOME) NOME, " + CRLF
	cQuery += " IIF(A1_COD IS NULL,A2_CGC, A1_CGC) CGC, " + CRLF
	cQuery += " CODIGO, " + CRLF
	cQuery += " LOJA, " + CRLF
	cQuery += " CT2.CT2_DATA, " + CRLF
	cQuery += " CT2.CT2_HIST, " + CRLF
	cQuery += " CT2.CT2_CREDIT, " + CRLF
	cQuery += " CT1_C.CT1_DESC01 Desc_Cred, " + CRLF
	cQuery += " CT2.CT2_DEBITO, " + CRLF
	cQuery += " CT1_D.CT1_DESC01 Desc_Deb " + CRLF
	cQuery += " FROM ( " + CRLF
	cQuery += " SELECT  CT2_DATA, " + CRLF
	cQuery += " SUBSTRING(IIF(CT2020.CT2_CLVLDB = '',CT2020.CT2_CLVLCR, CT2020.CT2_CLVLDB), 1, 1) TIPO, " + CRLF
	cQuery += " SUBSTRING(IIF(CT2020.CT2_CLVLDB = '',CT2020.CT2_CLVLCR, CT2020.CT2_CLVLDB), 2, 6) CODIGO, " + CRLF
	cQuery += " SUBSTRING(IIF(CT2020.CT2_CLVLDB = '',CT2020.CT2_CLVLCR, CT2020.CT2_CLVLDB), 8, 2) LOJA, " + CRLF
	cQuery += " CT2_HIST, " + CRLF
	cQuery += " CT2_CREDIT, " + CRLF
	cQuery += " CT2_DEBITO " + CRLF
	cQuery += " FROM CT2020 " + CRLF
	cQuery += " WHERE CT2020.D_E_L_E_T_ = '' " + CRLF

	If(!Empty(MV_PAR01))
		If(!Empty(MV_PAR02))
			cQuery += " AND CT2020.CT2_DATA BETWEEN '"+DtoS(MV_PAR01)+"' AND '"+DtoS(MV_PAR02)+"'" + CRLF
		EndIf
	Else
		cQuery += " AND CT2020.CT2_DATA BETWEEN '20241201' AND '20241203' " + CRLF
	EndIf
	If(!Empty(MV_PAR03))
		If(!Empty(MV_PAR04))
			cQuery += " AND CT2_CREDIT BETWEEN '"+AllTrim(MV_PAR03)+"'AND '"+AllTrim(MV_PAR04)+"' " + CRLF
		EndIf
	EndIf
	If(!Empty(MV_PAR05))
		If(!Empty(MV_PAR06))
			cQuery += " AND CT2_DEBITO BETWEEN '"+AllTrim(MV_PAR05)+"'AND '"+AllTrim(MV_PAR06)+"' " + CRLF
		EndIf
	EndIf
	cQuery += " ) CT2 " + CRLF
	cQuery += " LEFT JOIN SA1020 SA1 ON ( " + CRLF
	cQuery += " SA1.A1_FILIAL = '' " + CRLF
	cQuery += " AND SA1.D_E_L_E_T_ = '' " + CRLF
	cQuery += " AND TIPO = 'C' " + CRLF
	cQuery += " AND SA1.A1_COD = CODIGO " + CRLF
	cQuery += " AND SA1.A1_LOJA = LOJA " + CRLF
	cQuery += " ) " + CRLF
	cQuery += " LEFT JOIN SA2020 SA2 ON ( " + CRLF
	cQuery += " SA2.A2_FILIAL = '' " + CRLF
	cQuery += " AND SA2.D_E_L_E_T_ = '' " + CRLF
	cQuery += " AND TIPO = 'F' " + CRLF
	cQuery += " AND SA2.A2_COD = CODIGO " + CRLF
	cQuery += " AND SA2.A2_LOJA = LOJA " + CRLF
	cQuery += " ) " + CRLF
	cQuery += " LEFT JOIN CT1020 CT1_C ON ( " + CRLF
	cQuery += " CT1_C.CT1_FILIAL = '' " + CRLF
	cQuery += " AND CT1_C.D_E_L_E_T_ = '' " + CRLF
	cQuery += " AND CT2.CT2_CREDIT = CT1_C.CT1_CONTA " + CRLF
	cQuery += " ) " + CRLF
	cQuery += " LEFT JOIN CT1020 CT1_D ON ( " + CRLF
	cQuery += " CT1_D.CT1_FILIAL = '' " + CRLF
	cQuery += " AND CT1_D.D_E_L_E_T_ = '' " + CRLF
	cQuery += " AND CT2.CT2_DEBITO = CT1_D.CT1_CONTA " + CRLF
	cQuery += " ) " + CRLF

	cAliasTop := MPSysOpenQuery(cQuery)

	oSection:Init()

	While (!(cAliasTop)->(Eof()))

		oSection:Cell("NOME")           :SetValue((cAliasTop)->NOME)
		oSection:Cell("CNPJ")       :SetValue((cAliasTop)->CGC)
		oSection:Cell("CODIGO")       :SetValue((cAliasTop)->CODIGO)
		oSection:Cell("LOJA")       :SetValue((cAliasTop)->LOJA)
		oSection:Cell("DATA")       :SetValue((cAliasTop)->CT2_DATA)
		oSection:Cell("HISTORICO")       :SetValue((cAliasTop)->CT2_HIST)
		oSection:Cell("CREDITO")       :SetValue((cAliasTop)->CT2_CREDIT)
		oSection:Cell("DESC CREDITO")       :SetValue((cAliasTop)->Desc_Cred)
		oSection:Cell("DEBITO")       :SetValue((cAliasTop)->CT2_DEBITO)
		oSection:Cell("DESC DEBITO")       :SetValue((cAliasTop)->Desc_Deb)

		oSection:PrintLine()

		(cAliasTop)->(dbSkip())

	EndDo

	(cAliasTop)->(dbCloseArea())

	oSection:Finish()

Return
