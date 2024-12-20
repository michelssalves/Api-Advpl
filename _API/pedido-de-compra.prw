#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

User Function criarPedido()
  RpcClearenv()
   RPCSetType(3)
   RpcSetEnv('02')

    u_EXEC121()
    RpcClearEnv()
Return 
User FUnction EXEC121()

Local aCabec := {}
Local aItens := {}
Local aLinha := {}
Local nX := 0
Local cDoc := ""
Local nOpc := 3

PRIVATE lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "02" FILIAL "01" MODULO "COM"

dbSelectArea("SC7")

//Teste de Inclusão
cDoc := GetSXENum("SC7","C7_NUM")
SC7->(dbSetOrder(1))
While SC7->(dbSeek(xFilial("SC7")+cDoc))
ConfirmSX8()
cDoc := GetSXENum("SC7","C7_NUM")
EndDo

aadd(aCabec,{"C7_NUM" ,cDoc})
aadd(aCabec,{"C7_EMISSAO" ,dDataBase})
aadd(aCabec,{"C7_FORNECE" ,"007406"})
aadd(aCabec,{"C7_LOJA" ,"01"})
aadd(aCabec,{"C7_COND" ,"004"})
aadd(aCabec,{"C7_CONTATO" ,"AUTO"})
aadd(aCabec,{"C7_FILENT" ,cFilAnt})

For nX := 1 To 1
aLinha := {}
aadd(aLinha,{"C7_PRODUTO" ,"ST00005091     ",Nil})
aadd(aLinha,{"C7_QUANT" ,1 ,Nil})
aadd(aLinha,{"C7_PRECO" ,100 ,Nil})
aadd(aLinha,{"C7_TOTAL" ,100 ,Nil})
aadd(aItens,aLinha)
Next nX

MSExecAuto({|a,b,c,d,e,f,g,h| MATA120(a,b,c,d,e,f,g,h)},1,aCabec,aItens,nOpc,.F.,,,)

If !lMsErroAuto
ConOut("Incluido PC: "+cDoc)
Else
ConOut("Erro na inclusao!")
MostraErro()
EndIf

RESET ENVIRONMENT

// PREPARE ENVIRONMENT EMPRESA "02" FILIAL "01" MODULO "COM"

// dbSelectArea("SC7")

// //Teste de alteração
// nOpc := 4
// cDoc := "197538" //Informar PC ou AE (Alteração / Exclusão)

// aadd(aCabec,{"C7_NUM" ,cDoc})
// aadd(aCabec,{"C7_EMISSAO" ,dDataBase})
// aadd(aCabec,{"C7_FORNECE" ,"003515 "})
// aadd(aCabec,{"C7_LOJA" ,"10"})
// aadd(aCabec,{"C7_COND" ,"006"}) // Condição de pagamento que permite adiantamento
// aadd(aCabec,{"C7_CONTATO" ,"AUTO"})
// aadd(aCabec,{"C7_FILENT" ,cFilAnt})

// aLinha := {}

// // Alterar item existente
// aadd(aLinha,{"C7_ITEM" ,"0001" ,Nil})
// aadd(aLinha,{"C7_PRODUTO" ,"EM00002003     ",Nil})
// aadd(aLinha,{"C7_QUANT" ,2,Nil})
// aadd(aLinha,{"C7_PRECO" ,3779 ,Nil})
// aadd(aLinha,{"C7_TOTAL" ,5540 ,Nil})
// aAdd(aLinha,{"LINPOS","C7_ITEM" ,"0001"})
// aAdd(aLinha,{"AUTDELETA","N" ,Nil})
// aadd(aItens,aLinha)

// aLinha := {}
// // Incluir novo item no pedido
// aadd(aLinha,{"C7_ITEM" ,"0001" ,Nil})
// aadd(aLinha,{"C7_PRODUTO" ,"EV00920476     ",Nil})
// aadd(aLinha,{"C7_QUANT" ,2,Nil})
// aadd(aLinha,{"C7_PRECO" ,90 ,Nil})
// aadd(aLinha,{"C7_TOTAL" ,180 ,Nil}) 

// aadd(aItens,aLinha)

// PREPARE ENVIRONMENT EMPRESA "02" FILIAL "01" MODULO "COM"

// dbSelectArea("SC7")

// //Teste de exclusão
// nOpc := 5
// cDoc := "197539" //Informar PC ou AE (Alteração / Exclusão)

// aadd(aCabec,{"C7_NUM" ,cDoc})
// aadd(aCabec,{"C7_EMISSAO" ,dDataBase})
// aadd(aCabec,{"C7_FORNECE" ,"001 "})
// aadd(aCabec,{"C7_LOJA" ,"01"})
// aadd(aCabec,{"C7_COND" ,"001"})
// aadd(aCabec,{"C7_CONTATO" ,"AUTO"})
// aadd(aCabec,{"C7_FILENT" ,cFilAnt})

// For nX := 1 To 2
// aLinha := {}

// aadd(aLinha,{"C7_ITEM" ,StrZero(nX,4) ,Nil})
// aadd(aLinha,{"C7_PRODUTO" ,StrZero(nX,4),Nil})
// aadd(aLinha,{"C7_QUANT" ,1 ,Nil})
// aadd(aLinha,{"C7_PRECO" ,150 ,Nil})
// aadd(aLinha,{"C7_TOTAL" ,150 ,Nil})
// aadd(aItens,aLinha)
// Next nX

// MSExecAuto({|a,b,c,d,e| MATA120(a,b,c,d,e)},1,aCabec,aItens,nOpc,.F.)

// If !lMsErroAuto
// ConOut("Exclusao PC: "+cDoc)
// Else
// ConOut("Erro na exclusao!")
// MostraErro()
// EndIf

// RESET ENVIRONMENT

Return
