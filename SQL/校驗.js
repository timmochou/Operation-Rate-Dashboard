IF(ope != 'A2',INARRAY((P_CFC + P_VERSION + E8 + FORMAT(I8,'yyyy-MM-dd') + H8+J8)
,VALUE("DIC_CHECK",1)) = 0
,INARRAY((P_CFC + P_VERSION + E8 + FORMAT(I8,'yyyy-MM-dd') + H8 + J8 + P8 + R8 + V8),VALUE("DIC_CHECK",2)) = 0)


	
1ba677f6-3b49-412d-bf70-0c6308b6ee2c
IF(
    ope == 'A2',
    IF(
        INARRAY(
            (P_CFC + P_VERSION + E8 + FORMAT(I8,'yyyy-MM-dd') + H8),
            VALUE("DIC_CHECK",1)
        ) > 0,
        IF(
            D8 = DIC_CHECK.SELECT(
                ID,
                CHECK_ARR = (P_CFC + P_VERSION + E8 + FORMAT(I8,'yyyy-MM-dd') + H8)
            ),
            1,
            0
        ),
        0
    ),
    0
)




IF(ope != 'A2',INARRAY((P_CFC + P_VERSION + E8 + FORMAT(I8,'yyyy-MM-dd') + H8)
,VALUE("DIC_CHECK",1)) = 0 , TRUE)

t2.CFC_ENTITY_CODE 
|| t2.SCENARIO 
|| t2.CFC_INV_ENTITY_CODE 
||TO_CHAR(t2.DECLARATION_DATE, 'yyyy-MM-dd') 
|| t2.DIVIDEND_TYPE 
|| FISCAL_YEAR AS CHECK_ARR,


IF(ope == 'A2',INARRAY((P_CFC + P_VERSION + E8 + FORMAT(I8,'yyyy-MM-dd') + H8)
,VALUE("DIC_CHECK",1)) > 0
,IF(D8 = VALUE("DIC_CHECK",3,1,(P_CFC + P_VERSION + E8 + FORMAT(I8,'yyyy-MM-dd') + H8)),1,1),0)

