#INCLUDE 'totvs.ch'
#INCLUDE 'restful.ch'
#INCLUDE "topconn.ch"

WSRESTFUL zWSPedidos DESCRIPTION 'WebService Peddidos'

    WSDATA data1     AS STRING
    WSDATA data2     AS STRING
    WSDATA codigo    AS STRING
    WSDATA page      AS STRING
    WSDATA pageSize  AS STRING

    WSMETHOD POST NOVO DESCRIPTION "Versão 2 do Post sem parâmetro de path" PATH "/zWSPedidos/new/"  PATH 'new' PRODUCES APPLICATION_JSON"
    WSMETHOD GET ALLPO DESCRIPTION 'Todos os Pedido do Dia' WSSYNTAX '/zWSPedidos/get_all_po?{data1, data2}' PATH 'get_all_po' PRODUCES APPLICATION_JSON
    WSMETHOD GET FORNECEDOR DESCRIPTION 'Fornecedor por Codigo' WSSYNTAX '/zWSPedidos/get_fornecedor_details?{codigo}' PATH 'get_fornecedor_details' PRODUCES APPLICATION_JSON
   

END WSRESTFUL   

WSMETHOD GET ALLPO WSRECEIVE data1, data2 WSSERVICE zWSPedidos

    Local lRet       := .T.
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''

    cQuery := " SELECT  " + CRLF
    cQuery += " R_E_C_N_O_, " + CRLF
    cQuery += " C7_NUM, " + CRLF
    cQuery += " C7_ITEM, " + CRLF
    cQuery += " C7_PRODUTO, " + CRLF
    cQuery += " C7_DESCRI, " + CRLF
    cQuery += " C7_UM, " + CRLF
    cQuery += " C7_SEGUM, " + CRLF
    cQuery += " C7_QUANT, " + CRLF
    cQuery += " C7_QTSEGUM, " + CRLF
    cQuery += " C7_PRECO, " + CRLF
    cQuery += " C7_TOTAL, " + CRLF
    cQuery += " C7_COND, " + CRLF
    cQuery += " C7_FORNECE, " + CRLF
    cQuery += " C7_LOJA, " + CRLF
    cQuery += " C7_EMISSAO " + CRLF
    cQuery += " FROM SC7020  " + CRLF
    cQuery += " WHERE C7_EMISSAO BETWEEN '"+::data1+"' AND '"+::data2+"'  " + CRLF
    cQuery += " AND D_E_L_E_T_ = ''  " + CRLF

    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse['items'] := {}
    
    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['Id'] := cValToChar((cAliasTop)->R_E_C_N_O_)
        oRegistro['Pedido'] := AllTrim((cAliasTop)->C7_NUM)
        oRegistro['Item'] := AllTrim((cAliasTop)->C7_ITEM)
        oRegistro['Codigo'] := AllTrim((cAliasTop)->C7_PRODUTO)
        oRegistro['Produto'] := EncodeUTF8(AllTrim((cAliasTop)->C7_DESCRI)) 
        oRegistro['Un1A'] :=  AllTrim((cAliasTop)->C7_UM)
        oRegistro['Un2A'] :=  AllTrim((cAliasTop)->C7_SEGUM)
        oRegistro['Qtde1A'] :=  AllTrim(cValToChar((cAliasTop)->C7_QUANT))
        oRegistro['Qtde2A'] := AllTrim(cValToChar((cAliasTop)->C7_QTSEGUM))
        oRegistro['Preco'] := AllTrim(cValToChar((cAliasTop)->C7_PRECO))
        oRegistro['R$'] := AllTrim(cValToChar((cAliasTop)->C7_TOTAL))
        oRegistro['Pagamento'] :=  AllTrim((cAliasTop)->C7_COND)
        oRegistro['Condicao'] :=  FWNoAccent(Capital(AllTrim(GetAdvFVal("SE4","E4_DESCRI",xFilial("SE4") + (cAliasTop)->C7_COND ,1))))
        oRegistro['Fornecedor'] :=  AllTrim((cAliasTop)->C7_FORNECE)
        oRegistro['Loja'] :=  AllTrim((cAliasTop)->C7_LOJA)
        oRegistro['rzSocial'] :=  FWNoAccent(Capital(AllTrim(GetAdvFVal("SA2","A2_NREDUZ",xFilial("SA2") + (cAliasTop)->C7_FORNECE + (cAliasTop)->C7_LOJA ,1))))
        oRegistro['Data'] :=  DtoC(StoD((cAliasTop)->C7_EMISSAO))

        aAdd(jResponse['items'], oRegistro)
        (cAliasTop)->(DbSkip())

    EndDo
        
    (cAliasTop)->(DbCloseArea())
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD GET FORNECEDOR WSRECEIVE codigo WSSERVICE zWSPedidos

    Local lRet       := .T.
    Local oRegistro := {}

	DbSelectArea("SA2")
	SA2->(DbSetOrder(1)) //RA_FILIAL, RA_MAT, RA_NOME, R_E_C_N_O_, D_E_L_E_T_

	If ( SA2->(MsSeek(FWxFilial("SA2")+::codigo)) )

        oRegistro := JsonObject():New()
        oRegistro['loja']        := FWNoAccent(Capital(AllTrim(SA2->A2_LOJA)))
        oRegistro['razaoSocial'] := FWNoAccent(Capital(AllTrim(SA2->A2_NOME)))
        oRegistro['bloqueado']   := AllTrim(SA2->A2_MSBLQL)

	EndIf

    Self:SetContentType('application/json')
    Self:SetResponse(oRegistro:toJSON())

Return lRet

WSMETHOD POST NOVO WSSERVICE zWSPedidos
Local cBody

// recupera o body da requisição
cBody := ::GetContent()

::SetResponse('{"name":"thewsclass", "method":"post root"')

If !Empty(cBody)
::SetResponse(',"body":"'+cBody+'"')
Endif

::SetResponse('}')

Return .T.
