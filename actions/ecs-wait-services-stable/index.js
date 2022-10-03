import core from "@actions/core";
import { ECSClient, waitUntilServicesStable } from "@aws-sdk/client-ecs";

const ecsWait = async (runTaskConfig) => {
  const ecsClient = new ECSClient();
  await waitUntilServicesStable(
    { client: ecsClient, maxWaitTime: 600, maxDelay: 20, minDelay: 1 },
    {
      cluster: runTaskConfig.AWS_GEOMATCH_CLUSTER_ARN,
      services: [runTaskConfig.AWS_GEOMATCH_SERVICE_NAME],
    }
  );
};

const run = async () => {
  try {
    const config = core.getInput("ecs-run-task-config");
    await ecsWait(JSON.parse(config));
  } catch (error) {
    core.setFailed(error.stack);
  }
};

run();
