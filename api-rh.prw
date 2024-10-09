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

    WSMETHOD GET PIZZA DESCRIPTION 'Grafico de Pizaa' WSSYNTAX '/zWSDashRh/get_max_purchases?{tipo, mes, ano}' PATH 'get_max_purchases_pizza' PRODUCES APPLICATION_JSON
    WSMETHOD GET TABELA DESCRIPTION 'Tabela' WSSYNTAX '/zWSDashRh/get_table?{dataIni, custo, departamento, cargo}' PATH 'get_table' PRODUCES APPLICATION_JSON
    WSMETHOD GET ALLCC DESCRIPTION 'Lista de Custos' WSSYNTAX '/zWSDashRh/get_custo?{custo}' PATH 'get_custo' PRODUCES APPLICATION_JSON
    WSMETHOD GET ALLDPTO DESCRIPTION 'Lista de Departamentos' WSSYNTAX '/zWSDashRh/get_dpto?{custo, departamento, cargo}' PATH 'get_departamento' PRODUCES APPLICATION_JSON
    WSMETHOD GET ALLCARGOS DESCRIPTION 'Lista de Cargos' WSSYNTAX '/zWSDashRh/get_cargo?{custo, departamento, cargo}' PATH 'get_cargo' PRODUCES APPLICATION_JSON

END WSRESTFUL   

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
    Local aMatricula := {}
    Local i := 1
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
            cQuery += " AND SRA.RA_CC IN " + formatIn(::custo, ",") + CRLF
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

        cQuery := " SELECT SQB.QB_XDEPTO, QB_XDESCRI FROM SRA020 SRA " + CRLF
        cQuery += " JOIN SQB020 SQB ON SQB.QB_DEPTO = SRA.RA_DEPTO " + CRLF
        If !Empty(::departamento) .And. ::departamento <> '0'
            cQuery += "  AND SQB.QB_XDEPTO IN " + formatIn(::departamento, ",") + CRLF
            //cQuery += " AND SRA.RA_DEPTO= '"+::departamento+"'  " + CRLF
        EndIf
        cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRA.RA_SITFOLH != 'D' AND SQB.D_E_L_E_T_ = '' " + CRLF
        cQuery += " AND SRA.RA_CC IN " + formatIn(::custo, ",") + CRLF
        cQuery += " GROUP BY SQB.QB_XDEPTO, QB_XDESCRI " + CRLF
        cQuery += " ORDER BY SQB.QB_XDEPTO " + CRLF

        cAliasTop := MpSysOpenQuery( cQuery )

        While ! (cAliasTop)->(EoF())

            oRegistro := JsonObject():New()
            oRegistro['codigo'] := AllTrim((cAliasTop)->QB_XDEPTO)
            oRegistro['departamento'] := EncodeUTF8(AllTrim((cAliasTop)->QB_XDESCRI))
            aAdd(jResponse['tabela2'], oRegistro)
            (cAliasTop)->(DbSkip())
            
        EndDo

        (cAliasTop)->(DbCloseArea())

            cQuery := " SELECT SRA.RA_CODFUNC, SQ3.Q3_DESCSUM FROM SRA020 SRA  " + CRLF
            cQuery += " JOIN SQ3020 SQ3 ON SQ3.Q3_CARGO = SRA.RA_CODFUNC  " + CRLF
            cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRA.RA_SITFOLH != 'D' AND SQ3.D_E_L_E_T_ = '' " + CRLF  
            cQuery += " AND SRA.RA_CC IN " + formatIn(::custo, ",") + CRLF  
            If !Empty(::cargo) .And. ::cargo <> 'Null'
                cQuery += " AND SRA.RA_CODFUNC IN " + formatIn(::cargo, ",") + CRLF  
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
            If !Empty(::departamento) .And. ::departamento <> '0'
                cQuery += " INNER JOIN SQB020 SQB ON SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO AND SQB.QB_XDEPTO IN " + formatIn(::departamento, ",") + CRLF
                //cQuery += " AND SRA.RA_DEPTO = '"+::departamento+"' " + CRLF
            EndIf
            cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SRA.RA_SITFOLH != 'D' AND SRA.RA_CC IN " + formatIn(::custo, ",") + CRLF
            If !Empty(::cargo) .And. ::cargo <> 'Null'
                cQuery += " AND SRA.RA_CODFUNC IN " + formatIn(::cargo, ",") + CRLF
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

        (cAliasTop)->(DbCloseArea())

        If !Empty(::custo)

            For i := 1 To 3

                cQuery := " SELECT " + CRLF
                cQuery += " '"+aLabel[i]+"' AS TIPO, " + CRLF
                cQuery += " COUNT(*) AS VALOR, " + CRLF
                cQuery += " CONCAT('"+aLabel[i]+": ', COUNT(*)) AS INFO" + CRLF
                cQuery += " FROM " + CRLF
                cQuery += " SR8020 SR8 " + CRLF
                cQuery += " INNER JOIN SRA020 SRA ON SRA.RA_SITFOLH != 'D' AND RA_MAT=R8_MAT AND RA_CC IN " + formatIn(::custo, ",") + CRLF
                If !Empty(::departamento) .And. ::departamento != 'Null'
                cQuery += " INNER JOIN SQB020 SQB ON SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO AND SQB.QB_XDEPTO IN "+ formatIn(::departamento, ",") + CRLF
                //cQuery += " AND RA_DEPTO='"+::departamento+"' " + CRLF
                EndIf
                If !Empty(::cargo) .And. ::cargo != 'Null'
                    cQuery += " AND RA_CODFUNC IN " + formatIn(::cargo, ",") + CRLF
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
                cQuery += " AND ZA7.ZA7_CCUST IN " + formatIn(::custo, ",") + CRLF
                cQuery += " AND ZA7.ZA7_ANO = YEAR('"+::dataIni+"') " + CRLF
                If !Empty(::cargo) .And. ::cargo != 'Null'
                cQuery += " AND ZA7.ZA7_CFUNC IN " + formatIn(::cargo, ",") + CRLF
                EndIf
                If !Empty(::departamento) .And. ::departamento != 'Null'
                cQuery += " AND SQB.QB_XDEPTO IN " + formatIn(::departamento, ",") + CRLF
                EndIf

                cAliasTop := MpSysOpenQuery( cQuery )

                oRegistro := JsonObject():New()
                oRegistro['orcamento'] := (cAliasTop)->ORCAMENTO
                aAdd(jResponse['orcamento'], oRegistro)

                (cAliasTop)->(DbCloseArea())

            EndIf

        EndIf
 
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
    
   
    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['value'] := AllTrim((cAliasTop)->CTT_CUSTO)
        oRegistro['label'] := AllTrim((cAliasTop)->CTT_CUSTO) + " - " + EncodeUTF8(AllTrim((cAliasTop)->CTT_DESC01))
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

    cQuery := " SELECT SQB.QB_XDEPTO, QB_XDESCRI FROM SRA020 SRA  " + CRLF
    cQuery += " INNER JOIN SQB020 SQB ON SQB.QB_DEPTO = SRA.RA_DEPTO" + CRLF
    cQuery += " LEFT JOIN ZA8020 ZA8 ON ZA8.D_E_L_E_T_ = '' AND ZA8.ZA8_CLASSI = '1' AND ZA8.ZA8_CODIGO = SQB.QB_XDEPTO " + CRLF
    cQuery += " WHERE SRA.D_E_L_E_T_ = '' AND SQB.D_E_L_E_T_ = ''  AND SRA.RA_CC IN "+ formatIn(::custo, ",") + CRLF
    cQuery += " GROUP BY SQB.QB_XDEPTO, QB_XDESCRI" + CRLF
    cQuery += " ORDER BY SQB.QB_XDEPTO " + CRLF

    //  SELECT SQB.QB_XDEPTO, QB_XDESCRI, * FROM SQB020 SQB
    //  WHERE QB_CC IN ('001066','001030') AND D_E_L_E_T_ = ''

    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse['objects'] := {}
    
    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['value'] := AllTrim((cAliasTop)->QB_XDEPTO)
        oRegistro['label'] := AllTrim((cAliasTop)->QB_XDEPTO) + " - " + EncodeUTF8(AllTrim((cAliasTop)->QB_XDESCRI))
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
    cQuery += " INNER JOIN SQB020 SQB ON SQB.D_E_L_E_T_ = '' AND SQB.QB_DEPTO = SRA.RA_DEPTO AND SQB.QB_XDEPTO IN "+ formatIn(::departamento, ",") + CRLF
    cQuery += " INNER JOIN SRJ020 SRJ ON SRJ.D_E_L_E_T_ = '' AND SRJ.RJ_FUNCAO = SRA.RA_CODFUNC" + CRLF
    cQuery += " WHERE SRA.D_E_L_E_T_ = ''  AND SRA.RA_CC IN " + formatIn(::custo, ",") + CRLF
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

