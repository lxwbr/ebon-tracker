class Subsembly {
  final String? id;
  final int? acctId;
  final String ownrAcctCcy;
  final String? ownrAcctIban;
  final int? ownrAcctNo;
  final String? ownrAcctBic;
  final String? ownrAcctBankCode;
  final String bookgDt;
  final String? valDt;
  final String? txDt;
  final double amt;
  final String amtCcy;
  final String cdtDbtInd;
  final String? endToEndId;
  final String? pmtInfId;
  final String? mndtId;
  final String? cdtrId;
  final String? rmtInf;
  final String? purpCd;
  final String bookgTxt;
  final String? primaNotaNo;
  final String? bankRef;
  final String? bkTxCd;
  final String? rmtdNm;
  final String? rmtdUltmtNm;
  final String rmtdAcctCtry;
  final String? rmtdAcctIban;
  final String? rmtdAcctNo;
  final String? rmtdAcctBic;
  final String? rmtdAcctBankCode;
  final String? bookgSts;
  final String? btchBookg;
  final String? btchId;
  final String? gvc;
  final String? gvcExtension;
  final String? category;
  final String? categoryDt;
  final String? notes;
  final String readStatus;
  final String flag;

  Subsembly(
      {this.id,
      this.acctId,
      required this.ownrAcctCcy,
      this.ownrAcctIban,
      this.ownrAcctNo,
      this.ownrAcctBic,
      this.ownrAcctBankCode,
      required this.bookgDt,
      this.valDt,
      this.txDt,
      required this.amt,
      required this.amtCcy,
      required this.cdtDbtInd,
      this.endToEndId,
      this.pmtInfId,
      this.mndtId,
      this.cdtrId,
      this.rmtInf,
      this.purpCd,
      required this.bookgTxt,
      this.primaNotaNo,
      this.bankRef,
      this.bkTxCd,
      this.rmtdNm,
      this.rmtdUltmtNm,
      required this.rmtdAcctCtry,
      this.rmtdAcctIban,
      this.rmtdAcctNo,
      this.rmtdAcctBic,
      this.rmtdAcctBankCode,
      this.bookgSts,
      this.btchBookg,
      this.btchId,
      this.gvc,
      this.gvcExtension,
      this.category,
      this.categoryDt,
      this.notes,
      required this.readStatus,
      required this.flag});

  static List<String> headers = [
    "Id",
    "AcctId",
    "OwnrAcctCcy",
    "OwnrAcctIBAN",
    "OwnrAcctNo",
    "OwnrAcctBIC",
    "OwnrAcctBankCode",
    "BookgDt",
    "ValDt",
    "TxDt",
    "Amt",
    "AmtCcy",
    "CdtDbtInd",
    "EndToEndId",
    "PmtInfId",
    "MndtId",
    "CdtrId",
    "RmtInf",
    "PurpCd",
    "BookgTxt",
    "PrimaNotaNo",
    "BankRef",
    "BkTxCd",
    "RmtdNm",
    "RmtdUltmtNm",
    "RmtdAcctCtry",
    "RmtdAcctIBAN",
    "RmtdAcctNo",
    "RmtdAcctBIC",
    "RmtdAcctBankCode",
    "BookgSts",
    "BtchBookg",
    "BtchId",
    "GVC",
    "GVCExtension",
    "Category",
    "CategoryDt",
    "Notes",
    "ReadStatus",
    "Flag"
  ];

  List<String> get toCsv => [
        id?.toString() ?? "",
        acctId?.toString() ?? "",
        ownrAcctCcy,
        ownrAcctIban?.toString() ?? "",
        ownrAcctNo?.toString() ?? "",
        ownrAcctBic?.toString() ?? "",
        ownrAcctBankCode?.toString() ?? "",
        bookgDt.toString(),
        valDt?.toString() ?? "",
        txDt?.toString() ?? "",
        amt.toString(),
        amtCcy.toString(),
        cdtDbtInd.toString(),
        endToEndId?.toString() ?? "",
        pmtInfId?.toString() ?? "",
        mndtId?.toString() ?? "",
        cdtrId?.toString() ?? "",
        rmtInf?.toString() ?? "",
        purpCd?.toString() ?? "",
        bookgTxt.toString(),
        primaNotaNo?.toString() ?? "",
        bankRef?.toString() ?? "",
        bkTxCd?.toString() ?? "",
        rmtdNm?.toString() ?? "",
        rmtdUltmtNm?.toString() ?? "",
        rmtdAcctCtry.toString(),
        rmtdAcctIban?.toString() ?? "",
        rmtdAcctNo?.toString() ?? "",
        rmtdAcctBic?.toString() ?? "",
        rmtdAcctBankCode?.toString() ?? "",
        bookgSts?.toString() ?? "",
        btchBookg?.toString() ?? "",
        btchId?.toString() ?? "",
        gvc?.toString() ?? "",
        gvcExtension?.toString() ?? "",
        category?.toString() ?? "",
        categoryDt?.toString() ?? "",
        notes?.toString() ?? "",
        readStatus.toString(),
        flag.toString()
      ];
}
