#INCLUDE 'totvs.ch'
#INCLUDE 'restful.ch'
#INCLUDE "topconn.ch"

WSRESTFUL zWSDashRh DESCRIPTION 'WebService Dashboard'

    WSDATA tipo          AS STRING
    WSDATA produto       AS STRING
    WSDATA produtos      AS ARRAY
    WSDATA custo         AS STRING
    WSDATA departamento  AS STRING
    WSDATA cargo         AS STRING
    WSDATA mes           AS STRING
    WSDATA ano           AS STRING
    WSDATA dataIni      AS STRING

    WSMETHOD GET ALL DESCRIPTION 'Todos' WSSYNTAX '/zWSDashRh/get_max_purchases' PATH 'get_max_purchases' PRODUCES APPLICATION_JSON
    WSMETHOD GET PIZZA DESCRIPTION 'Grafico de Pizaa' WSSYNTAX '/zWSDashRh/get_max_purchases?{tipo, mes, ano}' PATH 'get_max_purchases_pizza' PRODUCES APPLICATION_JSON
    WSMETHOD GET TABELA DESCRIPTION 'Tabela' WSSYNTAX '/zWSDashRh/get_table?{dataIni, custo, departamento, cargo}' PATH 'get_table' PRODUCES APPLICATION_JSON
    WSMETHOD GET COLUNAS DESCRIPTION 'Grafico de Colunas' WSSYNTAX '/zWSDashRh/get_max_purchases?{tipo, produto, ano}' PATH 'get_max_purchases_col' PRODUCES APPLICATION_JSON
    WSMETHOD GET LINHAS DESCRIPTION 'Grafico de Linhas' WSSYNTAX '/zWSDashRh/get_max_purchases?{tipo, produtos, ano}' PATH 'get_max_purchases_lin' PRODUCES APPLICATION_JSON
    WSMETHOD GET ALLPRODUCTS DESCRIPTION 'Produtos por Grupo' WSSYNTAX '/zWSDashRh/get_products?{tipo}' PATH 'get_products' PRODUCES APPLICATION_JSON
    WSMETHOD GET ALLGRUPOS DESCRIPTION 'Lista de Grupos' WSSYNTAX '/zWSDashRh/get_groups' PATH 'get_groups' PRODUCES APPLICATION_JSON
    WSMETHOD GET ALLCC DESCRIPTION 'Lista de Custos' WSSYNTAX '/zWSDashRh/get_custo?{custo}' PATH 'get_custo' PRODUCES APPLICATION_JSON
    WSMETHOD GET ALLDPTO DESCRIPTION 'Lista de Departamentos' WSSYNTAX '/zWSDashRh/get_dpto?{custo, departamento, cargo}' PATH 'get_departamento' PRODUCES APPLICATION_JSON
    WSMETHOD GET ALLCARGOS DESCRIPTION 'Lista de Cargos' WSSYNTAX '/zWSDashRh/get_cargo?{custo, departamento, cargo}' PATH 'get_cargo' PRODUCES APPLICATION_JSON

END WSRESTFUL   

WSMETHOD GET ALL WSSERVICE zWSDashRh

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

WSMETHOD GET PIZZA WSRECEIVE tipo, mes, ano  WSSERVICE zWSDashRh

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

WSMETHOD GET TABELA WSRECEIVE dataIni, custo, departamento, cargo WSSERVICE zWSDashRh

    Local lRet       := .T.
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''
    Local cMatriculas := ""
    Local aMatricula := {}
    Local i := 1
    Local aTipo :=  {'4', '1', '1'}
    Local aLabel :=  {'Ferias', 'Afastamento', 'Atestado'}
    Local cMes := ''


    jResponse['tabela1'] := {}
    jResponse['tabela2'] := {}
    jResponse['tabela3'] := {}
    jResponse['tabela4'] := {}
    jResponse['ferias'] := {}
    jResponse['afastamento'] := {}
    jResponse['atestado'] := {}
    jResponse['orcamento'] := {}


    If !Empty(::custo) .Or. ::custo = '0'

        cQuery := " SELECT SRA.RA_CC, CTT_DESC01 CUSTO FROM SRA020 SRA " + CRLF
        cQuery += " JOIN CTT020 CTT ON CTT.CTT_CUSTO = SRA.RA_CC " + CRLF
        cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRA.RA_SITFOLH != 'D' AND CTT.D_E_L_E_T_ = '' " + CRLF
        If !Empty(::custo)
            cQuery += " AND SRA.RA_CC = '"+::custo+"' " + CRLF
        EndIf
        cQuery += " GROUP BY SRA.RA_CC, CTT_DESC01 " + CRLF

        cAliasTop := MpSysOpenQuery( cQuery )


        While ! (cAliasTop)->(EoF())

            oRegistro := JsonObject():New()
            oRegistro['codigo'] := AllTrim((cAliasTop)->RA_CC)
            oRegistro['custo'] := EncodeUTF8(AllTrim((cAliasTop)->CUSTO))
            aAdd(jResponse['tabela1'], oRegistro)
            (cAliasTop)->(DbSkip())

        EndDo

        (cAliasTop)->(DbCloseArea())

        cQuery := " SELECT SRA.RA_DEPTO, SQB.QB_DESCRIC FROM SRA020 SRA " + CRLF
        cQuery += " JOIN SQB020 SQB ON SQB.QB_DEPTO = SRA.RA_DEPTO " + CRLF
        cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRA.RA_SITFOLH != 'D' AND SQB.D_E_L_E_T_ = '' " + CRLF
        cQuery += " AND SRA.RA_CC = '"+::custo+"' " + CRLF
        If !Empty(::departamento) .And. ::departamento <> '0'
            cQuery += " AND SRA.RA_DEPTO= '"+::departamento+"'  " + CRLF
        EndIf
        cQuery += " GROUP BY SRA.RA_DEPTO, SQB.QB_DESCRIC  " + CRLF

        cAliasTop := MpSysOpenQuery( cQuery )

        While ! (cAliasTop)->(EoF())

            oRegistro := JsonObject():New()
            oRegistro['codigo'] := AllTrim((cAliasTop)->RA_DEPTO)
            oRegistro['departamento'] := EncodeUTF8(AllTrim((cAliasTop)->QB_DESCRIC))
            aAdd(jResponse['tabela2'], oRegistro)
            (cAliasTop)->(DbSkip())
            
        EndDo

        (cAliasTop)->(DbCloseArea())

            cQuery := " SELECT SRA.RA_CODFUNC, SQ3.Q3_DESCSUM FROM SRA020 SRA  " + CRLF
            cQuery += " JOIN SQ3020 SQ3 ON SQ3.Q3_CARGO = SRA.RA_CODFUNC  " + CRLF
            cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRA.RA_SITFOLH != 'D' AND SQ3.D_E_L_E_T_ = '' " + CRLF  
            cQuery += " AND SRA.RA_CC = '"+::custo+"'  " + CRLF  
            If !Empty(::cargo) .And. ::cargo <> 'Null'
                cQuery += " AND SRA.RA_CODFUNC = '"+::cargo+"'  " + CRLF  
            EndIf
            cQuery += " GROUP BY SRA.RA_CODFUNC, SQ3.Q3_DESCSUM  " + CRLF

        cAliasTop := MpSysOpenQuery( cQuery )

        While ! (cAliasTop)->(EoF())

            oRegistro := JsonObject():New()
            oRegistro['codigo'] := AllTrim((cAliasTop)->RA_CODFUNC)
            oRegistro['funcao'] := EncodeUTF8(AllTrim((cAliasTop)->Q3_DESCSUM))
            aAdd(jResponse['tabela3'], oRegistro)
            (cAliasTop)->(DbSkip())
            
        EndDo

        (cAliasTop)->(DbCloseArea())

            cQuery := " SELECT RA_MAT, RA_NOME FROM SRA020 SRA  " + CRLF
            cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRA.RA_SITFOLH != 'D' AND SRA.RA_CC = '"+::custo+"' " + CRLF
            If !Empty(::departamento) .And. ::departamento <> '0'
                cQuery += " AND SRA.RA_DEPTO = '"+::departamento+"' " + CRLF
            EndIf
            If !Empty(::cargo) .And. ::cargo <> 'Null'
                cQuery += " AND SRA.RA_CODFUNC = '"+::cargo+"' " + CRLF
            EndIf
            cQuery += " ORDER BY RA_NOME " + CRLF
    
        cAliasTop := MpSysOpenQuery( cQuery )

        While ! (cAliasTop)->(EoF())

            oRegistro := JsonObject():New()
            oRegistro['matricula'] := AllTrim((cAliasTop)->RA_MAT)
            oRegistro['nome'] := EncodeUTF8(AllTrim((cAliasTop)->RA_NOME))
            aAdd(jResponse['tabela4'], oRegistro)
            aAdd(aMatricula, AllTrim((cAliasTop)->RA_MAT)) 

            (cAliasTop)->(DbSkip())
            
        EndDo

        // For i := 1 To Len(aMatricula)
        //     cMatriculas += "'" + AllTrim(aMatricula[i]) + "'"
            
        //     If i < Len(aMatricula)
        //         cMatriculas += ","  // Adiciona a vírgula entre os itens
        //     EndIf
        // Next i

        (cAliasTop)->(DbCloseArea())

        If !Empty(::custo)

            For i := 1 To 3

                // cQuery := " SELECT " + CRLF
                // cQuery += " '"+aLabel[i]+"' AS TIPO, " + CRLF
                // cQuery += " COUNT(*) AS VALOR, " + CRLF
                // cQuery += " CONCAT('"+aLabel[i]+": ', COUNT(*)) AS INFO" + CRLF
                // cQuery += " FROM SR8020 SR8 " + CRLF
                // cQuery += " JOIN RCM020 RCM ON RCM.RCM_TIPO = SR8.R8_TIPOAFA " + CRLF
                // cQuery += " JOIN SRA020 SRA ON SRA.RA_MAT = SR8.R8_MAT  " + CRLF
                // cQuery += " WHERE SR8.D_E_L_E_T_ = ''   " + CRLF
                // cQuery += " AND '"+::dataIni+"' BETWEEN SR8.R8_DATAINI AND SR8.R8_DATAFIM " + CRLF
                // cQuery += " AND R8_TIPOAFA = '"+aTipo[i]+"' " + CRLF
                // cQuery += " AND RA_CODFUNC = '"+::cargo+"' " + CRLF
                // cQuery += " AND R8_MAT IN ("+cMatriculas+") " + CRLF

                cQuery := " SELECT " + CRLF
                cQuery += " '"+aLabel[i]+"' AS TIPO, " + CRLF
                cQuery += " COUNT(*) AS VALOR, " + CRLF
                cQuery += " CONCAT('"+aLabel[i]+": ', COUNT(*)) AS INFO" + CRLF
                cQuery += " FROM " + CRLF
                cQuery += " SR8020 SR8 " + CRLF
                cQuery += " INNER JOIN SRA020 SRA ON SRA.RA_SITFOLH != 'D' AND RA_MAT=R8_MAT AND RA_CC='"+::custo+"' " + CRLF
                If !Empty(::departamento) .And. ::departamento != 'Null'
                cQuery += " AND RA_DEPTO='"+::departamento+"' " + CRLF
                EndIf
                If !Empty(::cargo) .And. ::cargo != 'Null'
                    cQuery += " AND RA_CODFUNC = '"+::cargo+"' " + CRLF
                EndIf
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
                cQuery += "         AND SR81.R8_DATA <= '"+::dataIni+"' " + CRLF
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
                    cQuery += " (SR8.R8_DATAFIM='' AND DATEDIFF ( DAY , SR8.R8_DATAINI , '"+::dataIni+"') > 120) " + CRLF
                    cQuery += " OR (SR8.R8_DATAFIM!='' AND DATEDIFF ( DAY , SR8.R8_DATAINI , SR8.R8_DATAFIM) > 120) " + CRLF
                    cQuery += " ) " + CRLF
                Else
                    cQuery += " AND ( '"+::dataIni+"' BETWEEN R8_DATAINI AND R8_DATAFIM OR R8_DATAFIM='' ) " + CRLF
                    cQuery += " AND R8_DURACAO <= 120 " + CRLF
                Endif 

                cAliasTop := MpSysOpenQuery( cQuery )
            
                    oRegistro := JsonObject():New()
                    oRegistro['label'] := (cAliasTop)->TIPO
                    oRegistro['data'] :=  (cAliasTop)->VALOR
                    oRegistro['tooltip'] := (cAliasTop)->INFO

                    If(i = 1)
                        aAdd(jResponse['ferias'], oRegistro)
                    Endif    
                    If(i = 2)    
                        aAdd(jResponse['afastamento'], oRegistro)
                    endif    
                    If(i = 3) 
                        aAdd(jResponse['atestado'], oRegistro)
                    Endif

                Next i

                (cAliasTop)->(DbCloseArea())

                cMes := "SUM(ZA7.ZA7_MES"+cValToChar(MONTH(STOD(::dataIni)))+") AS ORCAMENTO"

                cQuery := " SELECT "+cMes+" FROM ZA7020 ZA7 " + CRLF
                cQuery += " LEFT JOIN ZA8020 ZA8 ON ZA8.ZA8_CODIGO = ZA7.ZA7_CDEPTO " + CRLF
                cQuery += " LEFT JOIN SQB020 SQB ON SQB.QB_DESCRIC = ZA8.ZA8_DESCRI " + CRLF
                cQuery += " WHERE ZA7.D_E_L_E_T_ = '' AND ZA8.D_E_L_E_T_ = '' AND SQB.D_E_L_E_T_ = '' " + CRLF
                cQuery += " AND ZA7.ZA7_CCUST = '"+::custo+"' " + CRLF
                cQuery += " AND ZA7.ZA7_ANO = YEAR('"+::dataIni+"') " + CRLF
                If !Empty(::cargo) .And. ::cargo != 'Null'
                cQuery += " AND ZA7.ZA7_CFUNC = '"+::cargo+"' " + CRLF
                EndIf
                If !Empty(::departamento) .And. ::departamento != 'Null'
                cQuery += " AND SQB.QB_DEPTO = '"+::departamento+"' " + CRLF
                EndIf

                cAliasTop := MpSysOpenQuery( cQuery )

                oRegistro := JsonObject():New()
                oRegistro['orcamento'] := (cAliasTop)->ORCAMENTO
                aAdd(jResponse['orcamento'], oRegistro)

                (cAliasTop)->(DbCloseArea())

            EndIf

        // Else
            // oRegistro := JsonObject():New()
            // aAdd(jResponse['tabela1'], oRegistro)
            // aAdd(jResponse['tabela2'], oRegistro)
            // aAdd(jResponse['tabela3'], oRegistro)
            // aAdd(jResponse['tabela4'], oRegistro)
        EndIf
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD GET COLUNAS WSRECEIVE tipo, produto, ano WSSERVICE zWSDashRh

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

WSMETHOD GET LINHAS WSRECEIVE tipo, produtos, ano WSSERVICE zWSDashRh

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


WSMETHOD GET ALLPRODUCTS WSRECEIVE tipo WSSERVICE zWSDashRh

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

WSMETHOD GET ALLGRUPOS WSSERVICE zWSDashRh

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

WSMETHOD GET ALLCC WSSERVICE zWSDashRh

    Local lRet       := .T.
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''

    cQuery := " SELECT CTT_CUSTO, CTT_DESC01 FROM CTT020 CTT " + CRLF
    cQuery += " WHERE CTT.D_E_L_E_T_ = '' AND CTT_CUSTO > 0  AND CTT_BLOQ <> '1' " + CRLF
    cQuery += " ORDER BY CTT_CUSTO " + CRLF

    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse['objects'] := {}
    
    oRegistro := JsonObject():New()
    oRegistro['label'] := ''
    oRegistro['value'] := '0'
    aAdd(jResponse['objects'], oRegistro)
    
    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['label'] := AllTrim((cAliasTop)->CTT_CUSTO) + " - " + EncodeUTF8(AllTrim((cAliasTop)->CTT_DESC01))
        oRegistro['value'] := AllTrim((cAliasTop)->CTT_CUSTO)
        aAdd(jResponse['objects'], oRegistro)
        (cAliasTop)->(DbSkip())

    EndDo

    (cAliasTop)->(DbCloseArea())
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD GET ALLDPTO WSRECEIVE custo, departamento, cargo WSSERVICE zWSDashRh

    Local lRet       := .T.
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''

    cQuery := " SELECT SRA.RA_DEPTO, QB_DESCRIC FROM SRA020 SRA  " + CRLF
    cQuery += " JOIN SQB020 SBQ ON SBQ.QB_DEPTO = SRA.RA_DEPTO" + CRLF
    cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SBQ.D_E_L_E_T_ = '' AND SRA.RA_CC = '"+::custo+"' " + CRLF
        If !Empty(::departamento) .And. ::departamento <> '0'
            cQuery += " AND SRA.RA_DEPTO = '"+::departamento+"' " + CRLF
        EndIf
    cQuery += " GROUP BY SRA.RA_DEPTO, QB_DESCRIC" + CRLF
    cQuery += " ORDER BY RA_DEPTO " + CRLF

    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse['objects'] := {}

    oRegistro := JsonObject():New()
    oRegistro['label'] := ''
    oRegistro['value'] := '0'
    aAdd(jResponse['objects'], oRegistro)
    
    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['label'] := AllTrim((cAliasTop)->RA_DEPTO) + " - " + EncodeUTF8(AllTrim((cAliasTop)->QB_DESCRIC))
        oRegistro['value'] := AllTrim((cAliasTop)->RA_DEPTO)
        aAdd(jResponse['objects'], oRegistro)
        (cAliasTop)->(DbSkip())

    EndDo

    (cAliasTop)->(DbCloseArea())
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD GET ALLCARGOS WSRECEIVE custo, departamento, cargo WSSERVICE zWSDashRh

    Local lRet       := .T.
    Local cAliasTop := ''
    Local jResponse  := JsonObject():New()
    Local cQuery := ''

    cQuery := " SELECT SRA.RA_CODFUNC , SRJ.RJ_DESC FROM SRA020 SRA  " + CRLF
    cQuery += " JOIN SRJ020 SRJ ON SRJ.RJ_FUNCAO = SRA.RA_CODFUNC" + CRLF
    cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRJ.D_E_L_E_T_ = '' AND SRA.RA_CC = '"+::custo+"' " + CRLF
        If !Empty(::departamento) .And. ::departamento <> '0'
            cQuery += " AND SRA.RA_DEPTO = '"+::departamento+"' " + CRLF
        EndIf
        If !Empty(::cargo) .And. ::cargo <> 'Null'
            cQuery += " AND SRA.RA_CODFUNC = '"+::cargo+"' " + CRLF
        EndIf
    cQuery += " GROUP BY SRA.RA_CODFUNC , SRJ.RJ_DESC" + CRLF
    cQuery += " ORDER BY SRA.RA_CODFUNC " + CRLF
 //srj
    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse['objects'] := {}
    
    oRegistro := JsonObject():New()
    oRegistro['label'] := ''
    oRegistro['value'] := 'Null'
    aAdd(jResponse['objects'], oRegistro)

    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['label'] := AllTrim((cAliasTop)->RA_CODFUNC ) + " - " + EncodeUTF8(AllTrim((cAliasTop)->RJ_DESC))
        oRegistro['value'] := AllTrim((cAliasTop)->RA_CODFUNC )
        aAdd(jResponse['objects'], oRegistro)
        (cAliasTop)->(DbSkip())

    EndDo

    (cAliasTop)->(DbCloseArea())
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

