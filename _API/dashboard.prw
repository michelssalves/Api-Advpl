#INCLUDE 'totvs.ch'
#INCLUDE 'restful.ch'
#INCLUDE "topconn.ch"

WSRESTFUL zWSDash DESCRIPTION 'WebService Dashboard'

    WSDATA tipo        AS STRING
    WSDATA produto     AS STRING
    WSDATA produtos    AS ARRAY
    WSDATA mes         AS STRING
    WSDATA ano         AS STRING

    WSMETHOD GET ALL DESCRIPTION 'Todos' WSSYNTAX '/zWSDash/get_max_purchases' PATH 'get_max_purchases' PRODUCES APPLICATION_JSON
    WSMETHOD GET PIZZA DESCRIPTION 'Grafico de Pizaa' WSSYNTAX '/zWSDash/get_max_purchases?{tipo, mes, ano}' PATH 'get_max_purchases_pizza' PRODUCES APPLICATION_JSON
    WSMETHOD GET TABELA DESCRIPTION 'Tabela' WSSYNTAX '/zWSDash/get_max_purchases?{tipo, mes, ano}' PATH 'get_max_purchases_tab' PRODUCES APPLICATION_JSON
    WSMETHOD GET COLUNAS DESCRIPTION 'Grafico de Colunas' WSSYNTAX '/zWSDash/get_max_purchases?{tipo, produto, ano}' PATH 'get_max_purchases_col' PRODUCES APPLICATION_JSON
    WSMETHOD GET LINHAS DESCRIPTION 'Grafico de Linhas' WSSYNTAX '/zWSDash/get_max_purchases?{tipo, produtos, ano}' PATH 'get_max_purchases_lin' PRODUCES APPLICATION_JSON
    WSMETHOD GET ALLPRODUCTS DESCRIPTION 'Produtos por Grupo' WSSYNTAX '/zWSDash/get_products?{tipo}' PATH 'get_products' PRODUCES APPLICATION_JSON
    WSMETHOD GET ALLGRUPOS DESCRIPTION 'Lista de Grupos' WSSYNTAX '/zWSDash/get_groups' PATH 'get_groups' PRODUCES APPLICATION_JSON

END WSRESTFUL   

WSMETHOD GET ALL WSSERVICE zWSDash

    Local lRet       := .T.
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''

    cQuery := " SELECT TOP 10 SC7.C7_PRODUTO, SC7.C7_DESCRI, MAX(SC7.C7_PRECO) AS MAX_PRECO, SC7.C7_FORNECE, SA2.A2_NOME, SA2.A2_CGC " + CRLF
    cQuery += " FROM SC7020 SC7 " + CRLF
    cQuery += " LEFT JOIN SB1020 SB1 ON SB1.B1_COD = SC7.C7_PRODUTO " + CRLF
    cQuery += " LEFT JOIN SBM020 SBM ON SBM.BM_GRUPO = SB1.B1_GRUPO " + CRLF
    cQuery += " LEFT JOIN SA2020 SA2 ON SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA " + CRLF
    cQuery += " WHERE SC7.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SB1.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SBM.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SA2.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SBM.BM_GRUPO = 'LI' " + CRLF
    cQuery += "   AND MONTH(SC7.C7_EMISSAO) = MONTH(GETDATE()) " + CRLF
    cQuery += "   AND YEAR(SC7.C7_EMISSAO) = YEAR(GETDATE()) " + CRLF
    cQuery += " GROUP BY SC7.C7_PRODUTO, SC7.C7_DESCRI, SC7.C7_FORNECE, SA2.A2_NOME, SA2.A2_CGC " + CRLF
    cQuery += " ORDER BY MAX_PRECO DESC " + CRLF

    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse['objects'] := {}
    
    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['label'] := FWNoAccent(Capital(AllTrim((cAliasTop)->C7_PRODUTO)))
        oRegistro['data'] :=  (cAliasTop)->MAX_PRECO
        oRegistro['tooltip'] :=  AllTrim(cValToChar((cAliasTop)->C7_DESCRI))
         aAdd(jResponse['objects'], oRegistro)
        (cAliasTop)->(DbSkip())

    EndDo

    (cAliasTop)->(DbCloseArea())
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD GET PIZZA WSRECEIVE tipo, mes, ano  WSSERVICE zWSDash

    Local lRet       := .T.
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''

    cQuery := " SELECT TOP 10 SC7.C7_PRODUTO, REPLACE(SC7.C7_DESCRI,';','') DESCRICAO, MAX(SC7.C7_PRECO) AS MAX_PRECO, SC7.C7_FORNECE, SA2.A2_NOME, SA2.A2_CGC " + CRLF
    cQuery += " FROM SC7020 SC7 " + CRLF
    cQuery += " LEFT JOIN SB1020 SB1 ON SB1.B1_COD = SC7.C7_PRODUTO " + CRLF
    cQuery += " LEFT JOIN SBM020 SBM ON SBM.BM_GRUPO = SB1.B1_GRUPO " + CRLF
    cQuery += " LEFT JOIN SA2020 SA2 ON SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA " + CRLF
    cQuery += " WHERE SC7.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SB1.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SBM.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SA2.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SBM.BM_GRUPO =  '"+::tipo+"' " + CRLF 
    cQuery += "   AND MONTH(SC7.C7_EMISSAO) = '"+::mes+"' " + CRLF
    cQuery += "   AND YEAR(SC7.C7_EMISSAO) = '"+::ano+"' " + CRLF
    cQuery += " GROUP BY SC7.C7_PRODUTO, REPLACE(SC7.C7_DESCRI,';','') DESCRICAO, SC7.C7_FORNECE, SA2.A2_NOME, SA2.A2_CGC " + CRLF
    cQuery += " ORDER BY MAX_PRECO DESC " + CRLF

    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse['objects'] := {}
    
    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['label'] := AllTrim((cAliasTop)->C7_PRODUTO)
        oRegistro['data'] :=  (cAliasTop)->MAX_PRECO
        oRegistro['tooltip'] :=  FWNoAccent(Capital(AllTrim((cAliasTop)->DESCRICAO)))
         aAdd(jResponse['objects'], oRegistro)
        (cAliasTop)->(DbSkip())

    EndDo

    (cAliasTop)->(DbCloseArea())
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD GET TABELA WSRECEIVE tipo, mes, ano  WSSERVICE zWSDash

    Local lRet       := .T.
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''
    //Local cGrupo := ::tipo

    cQuery := " SELECT TOP 10 SC7.C7_PRODUTO, REPLACE(SC7.C7_DESCRI,';','') DESCRICAO, MAX(SC7.C7_PRECO) AS MAX_PRECO, SC7.C7_FORNECE, SA2.A2_NOME, SA2.A2_CGC, " + CRLF
    cQuery += " (SELECT TOP 1 SC7_INNER.C7_EMISSAO  " + CRLF
    cQuery += " FROM SC7020 SC7_INNER  " + CRLF
    cQuery += " WHERE SC7_INNER.C7_PRODUTO = SC7.C7_PRODUTO  " + CRLF
    cQuery += " AND SC7_INNER.C7_PRECO = MAX(SC7.C7_PRECO) " + CRLF
    cQuery += " AND SC7_INNER.D_E_L_E_T_ = '' " + CRLF
    cQuery += " ORDER BY SC7_INNER.C7_PRECO DESC, SC7_INNER.C7_EMISSAO DESC " + CRLF
    cQuery += " ) AS DATA_MAX_PRECO " + CRLF
    cQuery += " FROM SC7020 SC7 " + CRLF
    cQuery += " LEFT JOIN SB1020 SB1 ON SB1.B1_COD = SC7.C7_PRODUTO " + CRLF
    cQuery += " LEFT JOIN SBM020 SBM ON SBM.BM_GRUPO = SB1.B1_GRUPO " + CRLF
    cQuery += " LEFT JOIN SA2020 SA2 ON SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA " + CRLF
    cQuery += " WHERE SC7.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SB1.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SBM.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SA2.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "   AND SBM.BM_GRUPO =  '"+::tipo+"' " + CRLF 
    cQuery += "   AND MONTH(SC7.C7_EMISSAO) = '"+::mes+"' " + CRLF
    cQuery += "   AND YEAR(SC7.C7_EMISSAO) = '"+::ano+"' " + CRLF
    cQuery += " GROUP BY SC7.C7_PRODUTO, REPLACE(SC7.C7_DESCRI,';',''), SC7.C7_FORNECE, SA2.A2_NOME, SA2.A2_CGC " + CRLF
    cQuery += " ORDER BY MAX_PRECO DESC " + CRLF

    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse['objects'] := {}
    
    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['Codigo'] := AllTrim((cAliasTop)->C7_PRODUTO)
        oRegistro['Produto'] := EncodeUTF8(AllTrim((cAliasTop)->DESCRICAO))
        oRegistro['R$'] := AllTrim(cValToChar((cAliasTop)->MAX_PRECO)) 
        oRegistro['CodFor'] :=  AllTrim((cAliasTop)->C7_FORNECE)
        oRegistro['Fornecedor'] :=  AllTrim((cAliasTop)->A2_NOME)
        oRegistro['CNPJ'] :=  AllTrim((cAliasTop)->A2_CGC)
        oRegistro['Data'] :=  DtoC(StoD((cAliasTop)->DATA_MAX_PRECO))

        aAdd(jResponse['objects'], oRegistro)
        (cAliasTop)->(DbSkip())

    EndDo
        
    (cAliasTop)->(DbCloseArea())
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD GET COLUNAS WSRECEIVE tipo, produto, ano WSSERVICE zWSDash

    Local lRet       := .T.
    Local cAliasTop := ''

    Local jResponse  := JsonObject():New()
    Local cQuery := ''
    Local cType := "column"
    Local nCnt
    //Local cAno := YEAR(DATE()) - 2
    Local cAno := val(::ano) - 2
    Local aData := {}
    jResponse['objects'] := {}
    jResponse['objects2'] := {}
    for nCnt := 0 To 2
    cQuery := ''
    cAno := cValToChar(cAno)
    cQuery += " SELECT C7_EMISSAO, C7_PRODUTO, C7_DESCRI, MAX_PRECO,  ANO,MES " + CRLF
    cQuery += " FROM ( " + CRLF
    cQuery += "     SELECT SC7.C7_EMISSAO, SC7.C7_PRODUTO, SC7.C7_DESCRI, SC7.C7_PRECO AS MAX_PRECO,  YEAR(SC7.C7_EMISSAO) AS ANO, " + CRLF
    cQuery += "     MONTH(SC7.C7_EMISSAO) AS MES,ROW_NUMBER() OVER (ORDER BY MONTH(SC7.C7_EMISSAO) ASC) AS RowNum " + CRLF
    cQuery += "     FROM SC7020 SC7 " + CRLF
    cQuery += "     LEFT JOIN SB1020 SB1 ON SB1.B1_COD = SC7.C7_PRODUTO " + CRLF
    cQuery += "     LEFT JOIN SBM020 SBM ON SBM.BM_GRUPO = SB1.B1_GRUPO " + CRLF
    cQuery += "     WHERE SC7.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "       AND SB1.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "       AND SBM.D_E_L_E_T_ = ''  " + CRLF
    cQuery += "       AND SBM.BM_GRUPO = '"+::tipo+"' " + CRLF
    cQuery += "       AND YEAR(SC7.C7_EMISSAO) = "+cAno+" " + CRLF
    cQuery += "       AND SC7.C7_PRODUTO = '"+::produto+"' " + CRLF
    cQuery += " ) AS RankedResults " + CRLF
    cQuery += " WHERE RowNum > (SELECT COUNT(*) FROM SC7020 SC7 WHERE SC7.D_E_L_E_T_ = '' AND  YEAR(SC7.C7_EMISSAO) = "+cAno+" AND C7_PRODUTO = '"+::produto+"') - 3 " + CRLF
    cQuery += " ORDER BY MES ASC " + CRLF
    cAliasTop := MpSysOpenQuery( cQuery )
  
    aData := {}
    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()

        oRegistro['label'] := (cAliasTop)->ANO

        While ! (cAliasTop)->(EoF())  
            aAdd(aData, (cAliasTop)->MAX_PRECO) 
            
            (cAliasTop)->(DbSkip())
        EndDo 

        oRegistro['data'] :=  aData 
        oRegistro['type'] :=  cType

        aAdd(jResponse['objects'], oRegistro)

        (cAliasTop)->(DbSkip())

    EndDo
    cAno := val(cAno) + 1    
   (cAliasTop)->(DbCloseArea())
   Next
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD GET LINHAS WSRECEIVE tipo, produtos, ano WSSERVICE zWSDash

    Local aData := {}
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''
    Local nX
    Local nY
    Local aCores := {'color-10', 'color-07', 'color-04', 'color-09', , 'color-06', 'color-03', 'color-08', 'color-05', 'color-02', 'color-01'}
    Local cAno := val(::ano) - 5
    Local aAno  := {}
    Local aProducts := {}
    Local cTipo := ::tipo
    aProducts := strtokarr(::produtos, ",")
    
    jResponse['categories'] := {}
    jResponse['participation'] := {}
 
    cQuery := ''
    oAno := JsonObject():New()
    
    for nX := 1 to len(aProducts)
        cAliasTop := Prices(cAno, aProducts[nX], cTipo)
        oRegistro := JsonObject():New()
           
        cProduto :=  FWNoAccent(Capital(AllTrim(GetAdvFVal("SB1","B1_DESC",xFilial("SB1") + aProducts[nX],1))))
         
        oRegistro['label'] := SubStr( cProduto, 0, 10 )
        
        for nY := 1 To 6
            if(len(aAno) < 6)
                aAdd(aAno, cValToChar(cAno)) 
            endif
            if Empty((cAliasTop)->PRECO)
                nPreco := 0
            else
                nPreco := (cAliasTop)->PRECO
            endif
            aAdd(aData, nPreco ) 
            (cAliasTop)->(DbCloseArea())
            cAno := cAno + 1 
            cAliasTop := Prices(cAno, aProducts[nX], cTipo)
        Next   

        (cAliasTop)->(DbCloseArea())
        oRegistro['data'] :=  aData 
        oRegistro['color'] := aCores[nX]
        
        aAdd(jResponse['participation'], oRegistro)
        cAno := YEAR(DATE()) - 5
        aData := {}
    Next
        aAdd(jResponse['categories'], aAno)
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return 

Static Function Prices(cAno, aProducts, cTipo)

  Local cQuery := ''
  Local cAliasTop := ''
  cAno := cValToChar(cAno)

    cQuery := " SELECT C7_PRODUTO, REPLACE(C7_DESCRI,';','') DESCRICAO , ROUND(AVG(ISNULL(C7_PRECO, 0)),2) PRECO " + CRLF
    cQuery += " FROM SC7020 SC7 " + CRLF
    cQuery += " LEFT JOIN SB1020 SB1 ON SB1.B1_COD = SC7.C7_PRODUTO " + CRLF
    cQuery += " LEFT JOIN SBM020 SBM ON SBM.BM_GRUPO = SB1.B1_GRUPO " + CRLF
    cQuery += " WHERE SC7.D_E_L_E_T_ = '' " + CRLF
    cQuery += " AND SB1.D_E_L_E_T_ = '' " + CRLF
    cQuery += " AND SBM.D_E_L_E_T_ = '' " + CRLF
    cQuery += " AND SBM.BM_GRUPO = '"+cTipo+"' " + CRLF
    cQuery += " AND YEAR(SC7.C7_EMISSAO) = "+cAno+" " + CRLF
    cQuery += "   AND C7_PRODUTO = '"+aProducts+"' " + CRLF
    cQuery += " GROUP BY C7_PRODUTO, REPLACE(C7_DESCRI,';','') " + CRLF
    cAliasTop := MpSysOpenQuery( cQuery )

Return cAliasTop


WSMETHOD GET ALLPRODUCTS WSRECEIVE tipo WSSERVICE zWSDash

    Local lRet       := .T.
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''

    cQuery := " SELECT B1_COD, REPLACE(B1_DESC,';','') DESCRICAO" + CRLF
    cQuery += " FROM SB1020 SB1 (NOLOCK)  " + CRLF
    cQuery += " LEFT JOIN SBM020 SBM (NOLOCK) ON SBM.BM_GRUPO = SB1.B1_GRUPO   " + CRLF
    cQuery += " WHERE SB1.D_E_L_E_T_ = ''  " + CRLF
    cQuery += " AND SB1.B1_MSBLQL IN('2', '') " + CRLF
    cQuery += " AND SB1.B1_ATIVO IN( 'S', '') " + CRLF
    cQuery += " AND SBM.BM_GRUPO = '"+::tipo+"'  " + CRLF
    cQuery += " ORDER BY B1_DESC  " + CRLF
 

    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse['product'] := {}
    jResponse['products'] := {}
    
    While ! (cAliasTop)->(EoF())

        oProduto  := JsonObject():New()
        oProdutos := JsonObject():New()
        oProduto['label'] := AllTrim((cAliasTop)->B1_COD) + " - " + EncodeUTF8(AllTrim((cAliasTop)->DESCRICAO))
        oProduto['value'] := AllTrim((cAliasTop)->B1_COD)
        aAdd(jResponse['product'], oProduto)
        oProdutos['value'] := AllTrim((cAliasTop)->B1_COD)
        oProdutos['label'] := EncodeUTF8(AllTrim((cAliasTop)->DESCRICAO)) + " - " + AllTrim((cAliasTop)->B1_COD)
        aAdd(jResponse['products'], oProdutos)
        (cAliasTop)->(DbSkip())

    EndDo

    (cAliasTop)->(DbCloseArea())
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD GET ALLGRUPOS WSSERVICE zWSDash

    Local lRet       := .T.
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''

    cQuery := " SELECT SBM.BM_GRUPO, SBM.BM_DESC FROM SBM020 SBM" + CRLF
    cQuery += " WHERE SBM.D_E_L_E_T_ = '' " + CRLF
    cQuery += " ORDER BY SBM.BM_GRUPO " + CRLF

    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse['objects'] := {}
    
    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['label'] := AllTrim((cAliasTop)->BM_GRUPO) + " - " + EncodeUTF8(AllTrim((cAliasTop)->BM_DESC))
        oRegistro['value'] := AllTrim((cAliasTop)->BM_GRUPO)
        aAdd(jResponse['objects'], oRegistro)
        (cAliasTop)->(DbSkip())

    EndDo

    (cAliasTop)->(DbCloseArea())
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

