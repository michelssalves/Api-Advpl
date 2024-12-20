#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "TOPCONN.CH"

WSRESTFUL zWSMedicoes DESCRIPTION 'WebService'
    //Atributos
    WSDATA id         AS CHAR
    WSDATA updated_at AS CHAR
    WSDATA limit      AS NUMERIC
    WSDATA page       AS NUMERIC
  
    //Métodos
    WSMETHOD GET  ID  DESCRIPTION 'Retorna ' WSSYNTAX '/zWSMedicoes/get_id?{id}' PATH 'get_id'        PRODUCES APPLICATION_JSON
    WSMETHOD GET  ALL DESCRIPTION 'Retorna ' WSSYNTAX '/zWSMedicoes/get_all/'    PATH 'get_all'       PRODUCES APPLICATION_JSON
    
END WSRESTFUL

WSMETHOD GET ALL WSSERVICE zWSMedicoes

    cQuery := " SELECT CND_SITUAC,CND_CONTRA,CND_REVISA,CND_COMPET,CND_XDESCF,SA2.A2_NOME, SA2.A2_CGC,CND_VLLIQD, CND_VLSALD,CND_VLTOT,CND_VLCONT,CND_VLADIT, (CND_VLCONT - CND_VLTOT) AS SALDO"
    cQuery += " FROM CND020 CND (NOLOCK)  "
    cQuery += " JOIN SA2020 SA2 ON SA2.A2_COD = CND.CND_XFORNE AND SA2.A2_LOJA = CND.CND_XLJFOR "
    cQuery += " WHERE CND.D_E_L_E_T_= '' AND SA2.D_E_L_E_T_= '' "
    cQuery += " AND CND.CND_SITUAC = 'A' "
    cQuery += " ORDER BY CND.R_E_C_N_O_ DESC  "

    cAliasTop := MpSysOpenQuery( cQuery )

    jResponse := JsonObject():New()
    jResponse['objects'] := {}

    While ! (cAliasTop)->(EoF())

        oRegistro := JsonObject():New()
        oRegistro['medicao'] := (cAliasTop)->CND_SITUAC 
        oRegistro['contrato'] := (cAliasTop)->CND_CONTRA 
        oRegistro['revisao'] := (cAliasTop)->CND_REVISA 
        oRegistro['competencia'] := (cAliasTop)->CND_COMPET 
        oRegistro['fornecedor'] := (cAliasTop)->CND_XDESCF 
        oRegistro['cnpj'] := (cAliasTop)->A2_CGC
        oRegistro['valor'] := cValToChar((cAliasTop)->CND_VLLIQD) 
        oRegistro['saldoMedicao'] := cValToChar((cAliasTop)->CND_VLSALD) 
        oRegistro['totalMedicao'] := cValToChar((cAliasTop)->CND_VLTOT) 
        oRegistro['valorAditivo'] := cValToChar((cAliasTop)->CND_VLADIT) 
        oRegistro['valorContrato'] := cValToChar((cAliasTop)->CND_VLCONT) 
        oRegistro['valorTotal'] := cValToChar((cAliasTop)->CND_VLTOT) 
        oRegistro['saldoPos'] := cValToChar((cAliasTop)->SALDO)
        aAdd(jResponse['objects'], oRegistro)

        (cAliasTop)->(DbSkip())

    EndDo

    (cAliasTop)->(DbCloseArea())
 
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())
Return 
