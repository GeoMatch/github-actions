import core from "@actions/core";
import {
  ECSClient,
  RunTaskCommand,
  waitUntilTasksStopped,
} from "@aws-sdk/client-ecs";

const runTaskSync = async (runTaskConfig, cmd, useExecForm) => {
  let command;
  if (useExecForm && cmd.startsWith("[") && cmd.endsWith("]")) {
    command = JSON.parse(cmd);
  } else if (useExecForm) {
    command = cmd.split(" ");
  } else {
    command = ["sh", "-c", cmd];
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
          cpu: 2,
          memory: 6144,
          environment: [
            {
              name: "SKIP_HEALTHCHECK",
              value: "true",
            },
          ],
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
  await waitUntilTasksStopped(
    { client: ecsClient, maxWaitTime: 1200, maxDelay: 60, minDelay: 1 },
    { cluster: runTaskConfig.AWS_GEOMATCH_CLUSTER_ARN, tasks: [taskArn] }
  );
  return taskArn;
};

const run = async () => {
  try {
    const config = core.getInput("ecs-run-task-config");
    const taskArn = await runTaskSync(
      JSON.parse(config),
      core.getInput("command"),
      core.getInput("shell-form") === "false"
    );
    core.setOutput("task-arn", taskArn);
  } catch (error) {
    core.setFailed(error.stack);
  }
};

run();
