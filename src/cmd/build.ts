import { basename, join } from "path";
import { existsSync, mkdirSync } from "fs";
import { exit } from "process";
import { glob } from "glob";
import { spawn } from "promisify-child-process";

export interface BuildProp {
  buildVersion: string;
  source: string;
  output: string;
  runner: string;
  project: string;
}

export async function build(options: BuildProp) {
  const projectDir = join(__dirname, "..", "..", "projects", options.project);
  const runnerScript = join(projectDir, `runner_${options.runner}`);

  if (!existsSync(runnerScript)) {
    console.error(
      `Project ${options.project} does not have runner ${options.runner}! Maybe recheck documentation?`,
    );
    exit(1);
  }

  const sourcesOutput = join(options.output, "sources");
  const binariesOutput = join(options.output, "binaries");

  mkdirSync(sourcesOutput, { recursive: true });
  mkdirSync(binariesOutput, { recursive: true });

  for (const builderFullPath of await glob(
    join(projectDir, "build_source_*"),
  )) {
    const builder = basename(builderFullPath);
    console.log(`Running ${builder}`);

    const { code } = await spawn(
      runnerScript,
      [builder, options.source, sourcesOutput, options.buildVersion],
      { stdio: ["ignore", "inherit", "inherit"] },
    );

    if (code !== 0) {
      console.log(`Builder ${builder} returns non-zero exit code: ${code}!`);
      exit(1);
    }
  }

  for (const builderFullPath of await glob(
    join(projectDir, "build_binary_*"),
  )) {
    const builder = basename(builderFullPath);
    console.log(`Running ${builder}`);

    const { code } = await spawn(
      runnerScript,
      [builder, options.source, binariesOutput, options.buildVersion],
      { stdio: ["ignore", "inherit", "inherit"] },
    );

    if (code !== 0) {
      console.log(`Builder ${builder} returns non-zero exit code: ${code}!`);
      exit(1);
    }
  }

  console.log(`All builds are completed for version ${options.buildVersion}!`);
}
