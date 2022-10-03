const core = require("@actions/core");

try {
  const command = core.getInput("command");
  console.log(`Input CMD: ${command}`);
  let output = command;
  if (!(command.startsWith("[") && command.endsWith("]"))) {
    output = JSON.stringify(command.split(" "));
  }
  console.log(`Output CMD: ${output}`);
  core.setOutput("output", output);
} catch (error) {
  core.setFailed(error.message);
}
