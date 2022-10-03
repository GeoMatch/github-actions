import core from "@actions/core";
import { GetParameterCommand, SSMClient } from "@aws-sdk/client-ssm";

const getSSMParam = async (path) => {
  const ssmClient = new SSMClient();
  const getCommand = new GetParameterCommand({ Name: path });
  const getCommandResult = await ssmClient.send(getCommand);
  return getCommandResult.Parameter.Value;
};

const run = async () => {
  try {
    const ssmPath = core.getInput("ssm-path");
    console.log(ssmPath);
    const val = await getSSMParam(ssmPath);
    console.log(val);
    core.setOutput("value", val);
  } catch (error) {
    core.setFailed(error.message);
  }
};

run();
