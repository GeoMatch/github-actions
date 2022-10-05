import core from "@actions/core";
import { GetParameterCommand, SSMClient } from "@aws-sdk/client-ssm";

const getSSMParam = async (name) => {
  const ssmClient = new SSMClient();
  const getCommand = new GetParameterCommand({
    Name: name,
    WithDecryption: true,
  });
  const getCommandResult = await ssmClient.send(getCommand);
  return getCommandResult.Parameter.Value;
};

const run = async () => {
  try {
    const ssmName = core.getInput("ssm-name");
    const val = await getSSMParam(ssmName);
    core.setOutput("value", val);
  } catch (error) {
    core.setFailed(error.message);
  }
};

run();
