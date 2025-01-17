#include 'protheus.ch'

// User Function CNT121LG()
//     Local aLegendas := ParamIXB[1]

//     aAdd(aLegendas, {"ALLtrim(CND_SITUAC) == 'AP'", "WHITE","Enviado para Aprovação"})
// Return aLegendas
User Function CN121ENC()
    Local lInTrans:= PARAMIXB[1] //Verdadeiro caso seja dentro da transação, Falso fora da transação
    Local lResult := PARAMIXB[2] //Verdadeiro caso encerramento tenha ocorrido com sucesso, falso caso tenha falhado por algum motivo.

    If lInTrans
        MsgInfo("Chamada dentro da transação."  ,"U_CN121ENC")
    Else
        MsgInfo("Chamada fora da transação."    ,"U_CN121ENC")
    EndIf

    If lResult
        MsgInfo("Encerramento OK."      ,"U_CN121ENC")
    Else
        MsgInfo("Encerramento Falhou."  ,"U_CN121ENC")
    EndIf

Return

User Function CN121EST()

    Local lInTrans  := PARAMIXB[2] //Verdadeiro caso seja dentro da transação, Falso fora da transação

    If lInTrans
        MsgInfo("Chamada dentro da transação."  ,"U_CN121EST")
    Else
        MsgInfo("Chamada fora da transação."    ,"U_CN121EST")
        //aqui enviar pro salesforce
    EndIf

Return
