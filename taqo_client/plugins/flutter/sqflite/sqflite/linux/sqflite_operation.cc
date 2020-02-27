#include "plugins/flutter/sqflite/sqflite/linux/sqflite_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

namespace sqflite_operation {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

}  // namespace

// abstract
class SqfliteOperation {
  public:
    virtual ~SqfliteOperation();

  private:
    virtual std::string getMethod();
    virtual std::string getSql();
    virtual EncodableList getSqlArguments();
    virtual int getInTransactionArgument();

    virtual void success(EncodableList &res);
    virtual void error(std::string errCode, std::string errMsg);
    virtual bool getNoResult();
    virtual bool getContinueOnError();
};

class SqfliteBatchOperation : public SqfliteOperation {
  public:
    virtual ~SqfliteBatchOperation();

    std::map<std::string, EncodableValue> dictionary;
    EncodableList results;
    std::string errorCode, errorMessage;
    bool noResult;
    bool continueOnError;

  private:
    std::string getMethod();
    std::string getSql();
    EncodableList getSqlArguments();
    int getInTransactionArgument();

    void success(EncodableList &res);
    void error(std::string errCode, std::string errMsg);
    bool getNoResult();
    bool getContinueOnError();

    void handleSuccess(EncodableList &results);
    void handleErrorContinue(EncodableList &results);
    void handleError(std::unique_ptr<flutter::MethodResult<EncodableValue>> result);
};

std::string SqfliteBatchOperation::getMethod() {
  return dictionary[SqfliteParamMethod].StringValue();
}

std::string SqfliteBatchOperation::getSql() {
  return dictionary[SqfliteParamSql].StringValue();
}

EncodableList SqfliteBatchOperation::getSqlArguments() {
  return dictionary[SqfliteParamSqlArguments].ListValue();
}

int SqfliteBatchOperation::getInTransactionArgument() {
  return dictionary[SqfliteParamInTransaction].IntValue();
}

void SqfliteBatchOperation::success(EncodableList &res) {
  results = res;
}

void SqfliteBatchOperation::error(std::string errCode, std::string errMsg) {
  errorCode = errCode;
  errorMessage = errMsg;
}

bool SqfliteBatchOperation::getNoResult() {
  return noResult;
}

bool SqfliteBatchOperation::getContinueOnError() {
  return continueOnError;
}

void SqfliteBatchOperation::handleSuccess(EncodableList &results) {
  if (!getNoResult()) {
    EncodableMap res;
    res[EncodableValue(SqfliteParamResult)] = results.empty() ? EncodableValue() : (EncodableValue) results;
    results.push_back((EncodableValue) res);
  }
}

void SqfliteBatchOperation::handleErrorContinue(EncodableList &results) {
  if (!getNoResult()) {
    EncodableMap err;
    err[EncodableValue(SqfliteParamErrorCode)] = EncodableValue(errorCode);
    err[EncodableValue(SqfliteParamErrorMessage)] = EncodableValue(errorMessage);
    // TODO
    err[EncodableValue(SqfliteParamErrorData)] = nullptr;

    EncodableMap res;
    res[EncodableValue(SqfliteParamError)] = (EncodableValue) err;
    results.push_back((EncodableValue) res);
  }
}

void SqfliteBatchOperation::handleError(std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  result->Error(errorCode, errorMessage);
}

class SqfliteMethodCallOperation : public SqfliteOperation  {
  public:
    virtual ~SqfliteMethodCallOperation();

    SqfliteMethodCallOperation newCallOperation(const flutter::MethodCall<EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

    flutter::MethodCall<EncodableValue> methodCall;
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result;

  private:
    std::string getMethod();
    std::string getSql();
    EncodableList getSqlArguments();
    int getInTransactionArgument();

    void success(EncodableList &res);
    void error(std::string errCode, std::string errMsg);
    bool getNoResult();
    bool getContinueOnError();
};

std::string SqfliteMethodCallOperation::getMethod() {
  return methodCall.method_name();
}

std::string SqfliteMethodCallOperation::getSql() {
  EncodableMap args(methodCall.arguments()->MapValue());
  return args[EncodableValue(SqfliteParamSql)].StringValue();
}

EncodableList SqfliteMethodCallOperation::getSqlArguments() {
  EncodableMap args(methodCall.arguments()->MapValue());
  return args[EncodableValue(SqfliteParamSqlArguments)].ListValue();
}

int SqfliteMethodCallOperation::getInTransactionArgument() {
  EncodableMap args(methodCall.arguments()->MapValue());
  return args[EncodableValue(SqfliteParamInTransaction)].IntValue();
}

void SqfliteMethodCallOperation::success(EncodableList &res) {
  EncodableValue rez(res);
  result->Success(&rez);
}

void SqfliteMethodCallOperation::error(std::string errCode, std::string errMsg) {
  result->Error(errCode, errMsg);
}

bool SqfliteMethodCallOperation::getNoResult() {
  EncodableMap args(methodCall.arguments()->MapValue());
  return args[EncodableValue(SqfliteParamNoResult)].BoolValue();
}

bool SqfliteMethodCallOperation::getContinueOnError() {
  EncodableMap args(methodCall.arguments()->MapValue());
  return args[EncodableValue(SqfliteParamContinueOnError)].BoolValue();
}

}  // namespace sqflite_operation
