#!/usr/bin/env node
import { Command } from "commander";
import { build } from "./cmd/build";

const packageJson = require("../package.json");

const program = new Command();
program
  .name(packageJson.name)
  .description(packageJson.description)
  .version(packageJson.version);

program
  .command("build")
  .description("Build from source repository to reproducible archives.")
  .requiredOption(
    "-s, --source <source>",
    "Source repository folder to build from",
  )
  .requiredOption("-b, --build-version <buildVersion>", "Release version")
  .requiredOption("-o, --output <output>", "Output folder for archives")
  .requiredOption("-u, --runner <runner>", "Reproducible runner to use")
  .option("-p, --project <project>", "Project to build", "ckb")
  .action(build);

if (!process.argv.slice(2).length) {
  program.outputHelp();
} else {
  // TODO: capture promise if needed
  program.parseAsync(process.argv);
}
