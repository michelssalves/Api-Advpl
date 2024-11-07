#Include "Protheus.ch"


/*/{Protheus.doc} xParambox
Função para explicar a função Parambox.

@author João Leão
@since  03/05/2023
@version 12/Superior
/*/

user function testando()

	RpcClearenv()
	RPCSetType(3)
	RpcSetEnv('02')

	oCtrDoc := TControleDocumento():New()

	// oCtrDoc:ValidateFile("mago.png", "")
	//oCtrDoc:InsertDocument("", "")

	//oCtrDoc:InsertACB("TCP 8050 - SPLIT.PDF")
	oCtrDoc:InsertAC9()

	// Local oReport	:= Nil
	// Local aPergs    := {}
	// Local aResps    := {}

	// AAdd(aPergs, {1, "Filial de", Space(TamSX3("C5_FILIAL")[1]) ,,,,, 20, .F.})
	// AAdd(aPergs, {1, "Filial até", Space(TamSX3("C5_FILIAL")[1]) ,,,,, 20, .F.})
	// AAdd(aPergs, {1, "Cliente de", Space(TamSX3("A1_COD")[1]) ,,,,, 30, .F.})
	// AAdd(aPergs, {1, "Cliente até", Space(TamSX3("A1_COD")[1]) ,,,,, 30, .F.})
	// AAdd(aPergs, {1, "Emissão de", SToD("") ,,,,, 50, .F.})
	// AAdd(aPergs, {1, "Emissão até", SToD("") ,,,,, 50, .F.})
	// AAdd(aPergs, {2, "Resultado", "1-Todos" ,{"1-Todos","2-Pedido de Venda","3-Nota Fiscal"},50,"",.F.})

	// If ParamBox(aPergs, "Parâmetros do relatório", @aResps,,,,,,,, .T., .T.)
	// 	oReport := ReportDef(aPergs)
	// 	oReport:PrintDialog()
	// EndIf

	RpcClearEnv()

Return

Static Function ReportDef(aResps)

	Local oReport		:= Nil
	Local oSection		:= Nil
	Local oBreak		:= Nil
	Local cAliasTop		:= ""
	Local cNomArq		:= "RELAT01_" + DToS(Date()) + StrTran(Time(),":","")
	Local cTitulo       := "Vendas e Faturamento"

	oReport := TReport():New(cNomArq, cTitulo, "", {|oReport| ReportPrint(oReport, @cAliasTop, aResps)}, "Este programa tem como objetivo imprimir informações do relatório.")
	oReport:SetLandscape() //modo paisagem
	//oReport:SetPortrait() //modo retrato

	oSection := TRSection():New(oReport, "Titulos", {},,,,,,.T.,,,,,,,,,,,,)

	TRCell():New(oSection,"FILIAL"         , nil, "Filial "          ,"@!", 3)
	// TRCell():New(oSection,"NOTAFISCAL"     , nil, "Nota Fiscal "     ,"@!", 6)
	// TRCell():New(oSection,"FORNECEDOR"     , nil, "Fornecedor"       ,"@!", 6)
	// TRCell():New(oSection,"LOJA"           , nil, "Loja"             ,"@!", 3)
	// TRCell():New(oSection,"RSOCIAL"        , nil, "R. Social"        ,"@!",10)
	// TRCell():New(oSection,"CNPJ/CPF"       , nil, "CNPJ/CPF"         ,"@R 99.999.999/9999-99",15)
	// TRCell():New(oSection,"EMISSAO"        , nil, "Emissão"          ,"@!", 8)
	// TRCell():New(oSection,"ESTADO"         , nil, "Estado"           ,"@!", 2)
	// TRCell():New(oSection,"DIGITACAO"      , nil, "Dt. Digitação"    ,"@!", 8)
	// TRCell():New(oSection,"ESPDOC"         , nil, "Tp. Doc."         ,"@!", 5)
	// TRCell():New(oSection,"VLRINSS"        , nil, "Vlr. INSS"        ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"VLRISS"         , nil, "Vlr. ISS"         ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"VLRPIS"         , nil, "Vlr PIS"          ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"VLRCOF"         , nil, "Vlr. Cofins"      ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"VLRCSLL"        , nil, "Vlr. CSLL"        ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"IRRET"          , nil, "IR Retido"        ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"IPI"            , nil, "IPI"        	     ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"VCTOREAL"       , nil, "Vcto. Real"       ,"@!", 8)
	// TRCell():New(oSection,"VLRTIT"         , nil, "Vlr. Liquido"       ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"VLRBRUTO"       , nil, "Vlr. Bruto"       ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"TOTAL_PEDIDO"   , nil, "Vlr. Pedido"      ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"TOTAL_NOTAS"    , nil, "Vlr. Notas"       ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"DIFERENCA"      , nil, "Saldo"   		 ,"@E 999,999,999,999.99", 17)
	// TRCell():New(oSection,"NUM_PEDIDO"     , nil, "Pedido Compras"   ,"@!", 6)
	// TRCell():New(oSection,"COND_DESCRI"    , nil, "Cond.Pag"         ,"@!", 50)
	// TRCell():New(oSection,"C7_USER"    	   , nil, "Nome Comprador"   ,"@!", 30)


Return(oReport)
User Function xParambox()

	Local aPergs        := {}
	Local aResps        := {}

	//[1]-Tipo 1 - MsGet
	//[2]-Descricao
	//[3]-String contendo o inicializador do campo
	//[4]-String contendo a Picture do campo
	//[5]-String contendo a validacao
	//[6]-Consulta F3
	//[7]-String contendo a validacao When
	//[8]-Tamanho do MsGet
	//[9]-Flag .T./.F. Parametro Obrigatorio ?
	//aAdd(aPergs, {1, "Produto", Space(15), "@!", "ExistCpo('SB1', mv_par01)",  "SB1", "", 50, .T.}) // Tipo caractere
	aAdd(aPergs, {1, "Data", SToD(""), "", "", "", "", 50, .T.}) // Tipo data

	//[1]-Tipo 6 - Arquivo
	//[2]-Descricao
	//[3]-String contendo o inicializador do campo
	//[4]-String contendo a Picture do campo
	//[5]-String contendo a validacao
	//[6]-String contendo a validacao When
	//[7]-Tamanho do MsGet
	//[8]-Flag .T./.F. Parametro Obrigatorio ?
	//[9]-Texto contendo os tipos de arquivo, exemplo: "Arquivos .CSV |*.CSV"
	//[10]-Diretorio inicial do cGetFile
	//[11]-Número relativo a visualização, podendo ser por diretório ou por arquivo (0,1,2,4,8,16,32,64,128)
	aAdd(aPergs, {6, "Informe o Arquivo:" , "", "", "", "", 80, .F., "Arquivos .CSV |*.CSV", "", GETF_LOCALHARD})
	aAdd(aPergs, {6, "Informe o Arquivo:" , "", "", "", "", 80, .F., "Arquivos .CSV |*.CSV", "", GETF_NETWORKDRIVE})

	If Parambox(aPergs, "Meu Input Box", @aResps)
		Alert("Usuário clicou no OK.")
	Else
		Alert("Operação cancelada pelo usuário")
	EndIf

Return
Static Function ReportPrint(oReport, cAliasTop, aResp)

	Local cAliaSC71 := ""

	oSection:Init()

	// While (!(cAliaSC71)->(Eof()))


	oSection:Cell("FILIAL")           :SetValue("IAL")
	// 	oSection:Cell("NOTAFISCAL")       :SetValue(SF1QRY->NOTA)
	// 	oSection:Cell("FORNECEDOR")       :SetValue(SF1QRY->FORNECEDOR)
	// 	oSection:Cell("LOJA")             :SetValue(SF1QRY->LOJA)
	// 	oSection:Cell("RSOCIAL")          :SetValue(SF1QRY->RAZAO)
	// 	oSection:Cell("CNPJ/CPF")         :SetValue(SF1QRY->CGC)
	// 	oSection:Cell("EMISSAO")          :SetValue(SUBSTR(SF1QRY->EMISSAO,7,2)+'/'+SUBSTR(SF1QRY->EMISSAO,5,2)+'/'+SUBSTR(SF1QRY->EMISSAO,1,4))
	// 	oSection:Cell("ESTADO")           :SetValue(SF1QRY->ESTADO)
	// 	oSection:Cell("VLRTIT")           :SetValue(SF1QRY->VLRLIQ)
	// 	oSection:Cell("DIGITACAO")        :SetValue(SUBSTR(SF1QRY->DIGITACAO,7,2)+'/'+SUBSTR(SF1QRY->DIGITACAO,5,2)+'/'+SUBSTR(SF1QRY->DIGITACAO,1,4))
	// 	oSection:Cell("ESPDOC")           :SetValue(SF1QRY->TIPO)
	// 	oSection:Cell("VLRINSS")          :SetValue(SF1QRY->VLRINSS)
	// 	oSection:Cell("VLRISS")           :SetValue(SF1QRY->VLRISS)
	// 	oSection:Cell("VLRPIS")           :SetValue(SF1QRY->VLRPIS)
	// 	oSection:Cell("VLRCOF")           :SetValue(SF1QRY->VLRCOFINS)
	// 	oSection:Cell("VLRCSLL")          :SetValue(SF1QRY->VLRCSLL)
	// 	oSection:Cell("IRRET")            :SetValue(SF1QRY->VLRIR)
	// 	oSection:Cell("IPI")              :SetValue((cAliaSC73)->IPI)
	// 	oSection:Cell("VCTOREAL")         :SetValue(SUBSTR(SF1QRY->VENCREAL,7,2)+'/'+SUBSTR(SF1QRY->VENCREAL,5,2)+'/'+SUBSTR(SF1QRY->VENCREAL,1,4))

	// 	cNota := AllTrim(u_zTiraZeros(SF1QRY->NOTA))
	// 	cForn := StrTran(StrTran(StrTran(u_ParteString(FwNoAccent(AllTrim(SF1QRY->RAZAO))), ".", " "), "/", " "), "-", " ")
	// 	cNome := Upper( AllTrim(TRANSFORM(SF1QRY->VLRLIQ, "@E 999999999.99")) + ' NF ' + cNota + '-' + cForn)
	// 	aAdd(aPedidos, (cAliaSC71)->C7_NUM)
	// 	i++
	// 	oSection:PrintLine()

	// 	SF1QRY->(dbSkip())
	// EndDo

	// SF1QRY->(dbCloseArea())

	oSection:Finish()

Return
Static Function REST006B()

	Local aArea   := FWGetArea()                            as Array
	Local cDirIni := GetTempPath()                          as Character
	Local cTipArq := ""                                     as Character
	Local cTitulo := "Seleção de Pasta para Salvar arquivo" as Character
	Local lSalvar := .F.                                    as Logical
	Local cPasta  := ""                                     as Character

	//Se não estiver sendo executado via job
	If ! IsBlind()

		//Chama a função para buscar arquivos
		cPasta := tFileDialog(;
			cTipArq,;                  // Filtragem de tipos de arquivos que serão selecionados
		cTitulo,;                  // Título da Janela para seleção dos arquivos
		,;                         // Compatibilidade
		cDirIni,;                  // Diretório inicial da busca de arquivos
		lSalvar,;                  // Se for .T., será uma Save Dialog, senão será Open Dialog
		GETF_RETDIRECTORY;         // Se não passar parâmetro, irá pegar apenas 1 arquivo; Se for informado GETF_MULTISELECT será possível pegar mais de 1 arquivo; Se for informado GETF_RETDIRECTORY será possível selecionar o diretório
		)

		If Empty(cPasta)
			FWAlertError("[REST006 - 01] - Nenhuma pasta foi selecionada. A rotina será encerrada! ", "SENTAX")
		EndIf

	EndIf

	FWRestArea(aArea)

Return cPasta
