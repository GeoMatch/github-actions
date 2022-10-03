import core from "@actions/core";
import {
  ECSClient,
  RunTaskCommand,
  waitUntilTasksStopped,
} from "@aws-sdk/client-ecs";

const runTaskSync = async (runTaskConfig, cmd) => {
  let command = cmd;
  if (!(command.startsWith("[") && command.endsWith("]"))) {
    command = JSON.stringify(command.split(" "));
  }

  const ecsClient = new ECSClient();
  const runTaskCommand = new RunTaskCommand({
    count: 1,
    launchType: "FARGATE",
    cluster: runTaskConfig.AWS_GEOMATCH_CLUSTER_ARN,
    taskDefinition: runTaskConfig.AWS_GEOMATCH_TASK_DEF_ARN,
    overrides: {
      containerOverrides: [
        {
          name: runTaskConfig.AWS_GEOMATCH_ECS_CONTAINER_NAME,
          command: command,
        },
      ],
    },
    networkConfiguration: {
      awsvpcConfiguration: {
        subnets: [runTaskConfig.AWS_GEOMATCH_TASK_SUBNET],
        securityGroups: [runTaskConfig.AWS_GEOMATCH_TASK_SECURITY_GROUP],
        assignPublicIp: "ENABLED",
      },
    },
  });
  const ecsTask = await ecsClient.send(runTaskCommand);
  const taskArn = ecsTask.tasks[0].taskArn;
  if (typeof taskArn !== "string") {
    throw Error("Task ARN is not defined.");
  }
  const waitECSTask = await waitUntilTasksStopped(
    { client: ecsClient, maxWaitTime: 600, maxDelay: 20, minDelay: 1 },
    { cluster: runTaskConfig.AWS_GEOMATCH_CLUSTER_ARN, tasks: [taskArn] }
  );
  console.log(waitECSTask.state);
  return taskArn;
};

const run = async () => {
  try {
    const config = core.getInput("ecs-run-task-config");
    const taskArn = await runTaskSync(
      JSON.parse(config),
      core.getInput("command")
    );
    core.setOutput("task-arn", taskArn);
  } catch (error) {
    console.trace("Error");
    core.setFailed(error.stack);
  }
};

run();
