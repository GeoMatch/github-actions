import core from "@actions/core";
import { GetParameterCommand, SSMClient } from "@aws-sdk/client-ssm";

const getSSMParam = async (name) => {
  const ssmClient = new SSMClient();
  const getCommand = new GetParameterCommand({ Name: name });
  const getCommandResult = await ssmClient.send(getCommand);
  return getCommandResult.Parameter.Value;
};

const run = async () => {
  try {
    const ssmName = core.getInput("ssm-name");
    const val = await getSSMParam(ssmName);
    console.log(val);
    core.setOutput("value", val);
  } catch (error) {
    core.setFailed(error.message);
  }
};

run();
