#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} ACFG001
Converte arquivo sdfbra.txt gerado pela rotina APCFG300 - Gestão de Ambientes
para a release desejada (12.1.033, 12.1.2210 ou 12.1.2310)

*** Função sob licença de uso livre não podendo ser comercializada. ***

@type function
@version 12.1.2310 
@author Thiago Berna - www.berna.dev
@since 11/11/2023
/*/
User Function ACFG001
	Local aParam        as array
	Local aOpc          as array
	Local oArquivo      as object
	Local cLinhas       as character
	Local cArquivo      as character
	Local cDesRls       as character
	Local cOriRls       as character
	Local cOriEncRls    as character
	Local nPosRls       as numeric
	Local nPosOpcOri    as numeric
	Local nPosEncRls    as numeric
	Local nOpcA         as numeric
	aParam      := {}
	aOpc        := {"12.1.033 ", "12.1.2210", "12.1.2310"}
	cLinhas     := ""
	cArquivo    := ""
	cDesRls     := ""
	cOriRls     := ""
	cOriEncRls  := ""
	nPosRls     := 0
	nPosEncRls  := 0
	nOpcA       := 0

	FormBatch("Converter SDFBRA.TXT",;
		{"Essa rotina tem como objetivo converter o arquvio sdfbra.txt para a release desejada",;
		"12.1.033, 12.1.2210 ou 12.1.2310. Função sob licença de uso livre não podendo ser ",;
		"comercializada.",;
		"Desenvolvido por Thiago Berna - www.berna.dev"},;
		{{1, .T., {|o| nOpcA := 1, o:oWnd:End()}}, {2, .T.,{|o| nOpcA := 2, o:oWnd:End()}}})

	If nOpcA == 1
		//Carrega o arquivo para processamento
		cArquivo    := tFileDialog("Arquivos SDFBRA (sdfbra.txt)", "Seleção de Arquivos", , , .F., )

		If Empty(cArquivo)
			MsgInfo("Nenhum arquivo selecionado!", "Atenção")
		Else

			//Lê o arquivo selecionado.
			oArquivo := FWFileReader():New(cArquivo)

			If !oArquivo:Open()
				MsgInfo("Falha ao abrir o arquivo! " + oArquivo:Error():Message, "Atenção")
			Else
				cLinhas := oArquivo:FullRead()
			EndIf

			oArquivo:Close()

			//Identifica os parâmetros EM_RELEASE e EM_ENCREL do arquivo sdfbra.txt original.
			nPosRls     := AT("EM_RELEASE", cLinhas)
			nPosEncRls  := AT("EM_ENCREL", cLinhas)
			cOriRls     := SubStr(cLinhas, nPosRls + 10, 9)
			cOriEncRls  := SubStr(cLinhas, nPosEncRls + 10, 20)

			//Não disponibiliza a release de origem nas opções de release de destino.
			nPosOpcOri := AScan(aOpc, {|x| x == cOriRls})
			If nPosOpcOri > 0
				ADel(aOpc, nPosOpcOri)
				ASize(aOpc, Len(aOpc) - 1)
			EndIf

			//Seleciona a release de destino.
			AAdd(aParam ,{9, "Release de Origem: " + cOriRls, 200, 40, .T.})
			AAdd(aParam, {2, "Release de Destino", Len(aOpc), aOpc, 50, "", .T.})

			If ParamBox(aParam, "Parâmetros", , , , , , , , , .F., .T.)
				//Corrige problema da função ParamBox ao manter a opção inicial selecionada.
				If ValType(MV_PAR02) == "N"
					cDesRls := aOpc[MV_PAR02]
				Else
					cDesRls := MV_PAR02
				EndIf

				//Ajusta o parâmetro EM_ENCREL no arquivo sdfbra.txt de destino.
				//Obs.: Parâmetros de conhecimento público podendo ser visualizados sem restrição
				//dentro do arquivo sdfbra.txt gerado pela rotina padrão APCFG300 - Gestão de Ambientes.
				If cDesRls == "12.1.033 "
					cLinhas := SubStr(cLinhas, 1, nPosEncRls + 9) + "48F5ACB296E9D740CB7C" + SubStr(cLinhas, nPosEncRls + 30)
				ElseIf cDesRls == "12.1.2210"
					cLinhas := SubStr(cLinhas, 1, nPosEncRls + 9) + "48F5ACB296EBD642DB7C" + SubStr(cLinhas, nPosEncRls + 30)
				ElseIf cDesRls == "12.1.2310"
					cLinhas := SubStr(cLinhas, 1, nPosEncRls + 9) + "48F5ACB296EBD742DB7C" + SubStr(cLinhas, nPosEncRls + 30)
				EndIf

				//Ajusta o parâmetro EM_RELEASE no arquivo sdfbra.txt de destino.
				//Obs.: Parâmetros de conhecimento público podendo ser visualizados sem restrição
				//dentro do arquivo sdfbra.txt gerado pela rotina padrão APCFG300 - Gestão de Ambientes.
				cLinhas := SubStr(cLinhas, 1, nPosRls + 9) + cDesRls + SubStr(cLinhas, nPosRls + 19)

				//Renomeia o arquivo original para gerar um backup.
				FRename(cArquivo, SubStr(cArquivo, 1, AT("SDFBRA.TXT", UPPER(cArquivo)) - 1) + "bkp_sdfbra_" + DTOS(dDataBase) + "_" + StrTran(Time(),":","") + ".txt")

				//Gera um novo arquivo sdfbra.txt com os dados atualizados.
				oArquivo := FWFileWriter():New(cArquivo, .T.)

				If !oArquivo:Create()
					MsgInfo("Falha ao criar o novo arquivo! " + oArquivo:Error():Message, "Atenção")
				Else
					If !oArquivo:Write(cLinhas)
						MsgInfo("Falha ao escrever o novo arquivo! " + oArquivo:Error():Message, "Atenção")
					EndIf
					oArquivo:Close()
					MsgInfo("Arquivo " + cArquivo + " atualizado com sucesso!", "Atenção")
				EndIf
			Else
				MsgInfo("Processo cancelado pelo usuário!", "Atenção")
			EndIf
		EndIf
	Else
		MsgInfo("Processo cancelado pelo usuário!", "Atenção")
	EndIf

	FWFreeVar(@oArquivo)
	FWFreeVar(@aParam)
	FWFreeVar(@aOpc)

Return
