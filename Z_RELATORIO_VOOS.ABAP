*&---------------------------------------------------------------------*
*& Report Z_RELATORIO_VOOS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z_RELATORIO_VOOS.

* DECLARANDO TABELAS QUE IREI USAR
TABLES: SBOOK, SFLIGHT, SCARR. "ESTOU DIZENDO QUE VOU USAR ALGUNS CAMPOS QUE EXISTEM DENTRO DESSAS TABELAS

* CRIANDO TIPO - AQUI EU ESTOU CRIANDO UMA "TABELA" COM OS CAMPOS QUE IREI PRECISAR DAS TABELAS ACIMA
TYPES: BEGIN OF TY_DADOS,
CARRID         TYPE SCARR-CARRID,
CARRNAME       TYPE SCARR-CARRNAME,
CONNID         TYPE SBOOK-CONNID,
TOTAL_PAGO     TYPE SBOOK-LOCCURAM,
QTD_RESERVAS   TYPE I,
  END OF TY_DADOS.

* CRIANDO TABELA INTERNA
DATA: T_DADOS     TYPE TABLE OF   TY_DADOS,   " TABELA QUE CRIEI PARA USAR APENAS DENTRO DO PROGRAMA QUANDO EXECUTADO
      T_SORT      TYPE SLIS_T_SORTINFO_ALV,   " TABELA QUE USO PARA ORDENAR MEU RELATORIO
      T_FIELDCAT  TYPE SLIS_T_FIELDCAT_ALV,   " TABELA QUE USO PARA FAZER O FIELDCAT MANUALMENTE
      T_HEADER    TYPE   SLIS_T_LISTHEADER.   " TABELA QUE USO PARA ARMAZENAR O CABECALHO
*      T_RESULTADO TYPE TABLE OF TY_DADOS.

* CRIANDO WORK AREA
DATA: W_DADOS      TYPE          TY_DADOS,
      W_SORT       TYPE SLIS_SORTINFO_ALV,
      W_HEADER     TYPE   SLIS_LISTHEADER,
      W_LAYOUT     TYPE   SLIS_LAYOUT_ALV,
      W_FIELDCAT   TYPE SLIS_FIELDCAT_ALV.

* CRIANDO PARAMETROS
PARAMETERS: P_DATAI TYPE SBOOK-FLDATE, "DATAI - DATA DE INICIO DO VOO, ESTA SENDO BUSCADA NA TABELA SBOOK NO CAMPO FLDATE
            P_DATAF TYPE SBOOK-FLDATE. "DATAF - DATA DO FIM DO VOO, ESTA SENDO BUSCADA N  A TABELA SBOOK NO CAMPO FLDATE

AT SELECTION-SCREEN.
IF P_DATAF IS INITIAL.
  MESSAGE 'PREENCHA TODOS OS CAMPOS!' TYPE 'E'.
  ENDIF.

* VERIFICANDO SE OS  PARAMETROS ESTAO  FUNCIONANDO E DEIXANDO MENSAGEM PARA O USUARIO

  IF P_DATAI IS INITIAL.
    MESSAGE 'PREENCHA TODOS OS CAMPOS!' TYPE 'E'.
  ENDIF.

* INICIANDO A SELECAO DE DADOS
START-OF-SELECTION.
SELECT
  A~CARRID,                               "AQUI  ESTOU DIZENDO, SELECIONE ESSES 3 CAMPOS DAS TABELAS QUE FORAM DENOMINADA COMO "A"e "B"
  A~CARRNAME,
  B~CONNID,
  SUM( B~LOCCURAM ) AS TOTAL_PAGO,        " AQUI ESTOU DIZENDO QUE E PARA SOMAR O VALOR TOTAL DA VIAGEM E EU INDICO O CAMPO E A TABELA OU SEJA TABELA "B" CODIGO DO CAMPO "LOCCURAM'
  COUNT( * ) AS QTD_RESERVAS              " AQUI EU  BASICAMENTE PERGUNTO AO SISTEMA "QUANTOS REGISTROS TEM DENTRO DA TABELA QTD_RESERVAS?"
  INTO TABLE @T_DADOS
  FROM SCARR AS A
  INNER JOIN SBOOK AS B
  ON A~CARRID = B~CARRID
  WHERE B~FLDATE BETWEEN @P_DATAI AND @P_DATAF
  GROUP BY
  A~CARRID,
  A~CARRNAME,
  B~CONNID.
  END-OF-SELECTION.

  IF T_DADOS IS INITIAL.
    MESSAGE 'NENHUM REGISTRO ENCONTRADO COM ESSAS DATAS!' TYPE 'I'.
    LEAVE PROGRAM. "INTERROMPE O PROGRAMA E VOLTA PARA A TELA INICIAL"
    ENDIF.


PERFORM F_LAYOUT.
PERFORM F_FIELDCAT.
PERFORM F_SORT.
PERFORM F_DISPLAY.

*&---------------------------------------------------------------------*
*& Form F_DISPLAY
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_display .

* USADO PARA EXIBIR O RELATORIO ALV PARA O USUARIO

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
     I_CALLBACK_PROGRAM                = SY-REPID
     I_CALLBACK_TOP_OF_PAGE            = 'F_TOP_OF_PAGE'
     IS_LAYOUT                         = W_LAYOUT
     IT_FIELDCAT                       = T_FIELDCAT
     IT_SORT                           = T_SORT
     I_DEFAULT                         = 'X'
     I_SAVE                            = 'X'
    TABLES
      t_outtab                          = T_DADOS.
  IF sy-subrc <> 0.
MESSAGE 'ERRO AO EXIBIR  O RELATORIO ALV' TYPE 'I'.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form F_LAYOUT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_layout .

* USADO PARA DEFINIR O LAYOUT DO RELATORIO ALV

  W_LAYOUT-ZEBRA = 'X'.
*  W_LAYOUT-COLWIDTH_OPTIMIZE = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form F_TOP_OF_PAGE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_top_of_page .

* USADO PARA CRIACAO DO CABECALHO

* CRIANDO VARIAVEL LOCAL
DATA: VL_HORA TYPE SY-UZEIT,
      VL_DATA TYPE SY-DATUM,
      VL_USER TYPE SY-UNAME.

* CHAMANDO AS VARIAVEIS DECLARADAS
*  VL_HORA = SY-UZEIT.
  VL_DATA = SY-DATUM.
  VL_USER = SY-UNAME.

  WRITE: SY-DATUM TO VL_DATA DD/MM/YY.
  WRITE: SY-UNAME TO VL_USER.

*  PREENCHENDO CABECALHO
  CLEAR W_HEADER.
  W_HEADER-TYP  = 'H'.
  W_HEADER-INFO = 'RELATORIO DE VOOS COMERCIAIS'.
  APPEND W_HEADER TO T_HEADER.

  CLEAR W_HEADER.
  W_HEADER-TYP  = 'S'.
  W_HEADER-KEY  = 'DATA: '.
  W_HEADER-INFO = VL_DATA.
  APPEND W_HEADER TO T_HEADER.

  CLEAR W_HEADER.
  W_HEADER-TYP  = 'S'.
  W_HEADER-KEY  = 'USUARIO: '.
  W_HEADER-INFO = VL_USER.
  APPEND W_HEADER TO T_HEADER.

* FUNCAO PARA EXIBIR O CABECALHO
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary       = T_HEADER.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form F_FIELDCAT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM F_FIELDCAT .


* CRIANDO O FIELDCAT MANUALMENTE
CLEAR W_FIELDCAT.
W_FIELDCAT-FIELDNAME ='CARRID'.
W_FIELDCAT-SELTEXT_M   = 'CODIGO DA COMPANHIA AEREA'.
W_FIELDCAT-COL_POS   = 1.
APPEND W_FIELDCAT TO T_FIELDCAT.

CLEAR W_FIELDCAT.
W_FIELDCAT-FIELDNAME ='CARRNAME'.
W_FIELDCAT-SELTEXT_M   = 'COMPANHIA AEREA'.
W_FIELDCAT-COL_POS   = 2.
APPEND W_FIELDCAT TO T_FIELDCAT.

CLEAR W_FIELDCAT.
W_FIELDCAT-FIELDNAME ='CONNID'.
W_FIELDCAT-SELTEXT_M   = 'CODIGO DO VOO'.
W_FIELDCAT-COL_POS   = 3.
APPEND W_FIELDCAT TO T_FIELDCAT.

CLEAR W_FIELDCAT.
W_FIELDCAT-FIELDNAME ='QTD_RESERVAS'.
W_FIELDCAT-SELTEXT_M   = 'NUMERO DE RESERVAS'.
W_FIELDCAT-COL_POS   = 4.
APPEND W_FIELDCAT TO T_FIELDCAT.

CLEAR W_FIELDCAT.
W_FIELDCAT-FIELDNAME ='TOTAL_PAGO'.
W_FIELDCAT-SELTEXT_M   = 'VALOR TOTAL'.
W_FIELDCAT-COL_POS   = 5.
APPEND W_FIELDCAT TO T_FIELDCAT.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form F_SORT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_sort .

 CLEAR W_SORT.
W_SORT-SPOS =      1.
W_SORT-FIELDNAME = 'CARRID'.
W_SORT-UP =        'X'. "ORDENNA PELA ORDEM CRESCENTE
W_SORT-SUBTOT =    'X'.
APPEND W_SORT TO T_SORT.
ENDFORM.