import { Configuration, OpenAIApi } from "openai";
import { argv } from "process";
import fs from "fs-extra";
import glob from "glob-promise";
import path from "path";
import yaml from "js-yaml";

class Main {
  async run(args: string[]) {
    const promptNumber = args[2];
    const promptFile = path.join(__dirname, '../../../data/sentences/prompts/', `${promptNumber}.txt`);
    const promptSrc = await this.loadPrompt(promptFile);

    const circleFileName = args[3];
    const isFloor = circleFileName.match(/^\d+$/);
    let circle: string[][];
    if (isFloor) {
      circle = await this.loadFloors(Number(circleFileName))
    } else {
      // Load words file and get 4 items list
      const circleFile = path.join(__dirname, '../../../data/circles/', circleFileName)
      circle = await this.loadCircle(circleFile);
    }

    let prompt = promptSrc[0];
    const sentences = [];
    for (let i = 0; i < 4; i++) {
      const words = circle[i];
      prompt += promptSrc[1] + words.join(", ") + ".\n";
      const result = await this.sendRequest(prompt);
      prompt += result[0].text + "\n";
      const sentence = result[0].text?.replace(/^.+?AI: /s, "").trim();
      sentences.push(sentence)
      console.log(sentence)
    }

    let outFile;
    let yaml = "";
    if (isFloor) {
      outFile = path.join(__dirname, '../../../data/sentences/floors/', circleFileName + ".yml");
    } else {
      outFile = path.join(__dirname, '../../../data/sentences/', circleFileName);
      yaml += "source: " + circleFileName + "\n";
    }
    yaml += "generator: text-davinci-003\n"
      + "prompt: " + promptNumber + "\n"
      + "--- |\n"
      + sentences.join("\n\n") + "\n";
    await fs.writeFile(outFile, yaml);
  }

  async loadFloors(floorNumber: number): Promise<string[][]> {
    const allFiles = await glob(path.join(__dirname, '../../../data/circles/*.yml'));
    const isLastFloor = floorNumber == 83;
    const startPos = (floorNumber - 1) * 12
    const endPos = startPos + (isLastFloor ? 16 : 12);
    const files = allFiles.slice(startPos, endPos);

    const result: string[][] = [[], [], [], []];
    for (let i = 0; i < files.length; i++) {
      const words = yaml.load(await fs.readFile(files[i], "utf-8")) as string[];
      const q = Math.floor(i / (isLastFloor ? 4 : 3));
      result[q].push(words[0]);
    }
    return result;
  }

  async loadCircle(circleFile: string) {
    const words = yaml.load(await fs.readFile(circleFile, "utf-8")) as string[];
    const result = [];
    const unit = words.length / 4;
    for (let i = 0; i < 4; i++) {
      result.push(words.slice(i * unit, (i + 1) * unit));
    }
    return result;
  }

  async loadPrompt(promptFile: string) {
    if (!promptFile) {
      console.error("No prompt file specified");
      process.exit(1);
    }

    let prompt: string = await fs.readFile(promptFile, "utf-8");
    prompt = prompt.trim();
    let m = prompt.match(/^(.+)\n([^\n]+)$/s);
    if (!m) {
      console.error("Invalid prompt file");
      process.exit(1);
    }
    return [m[1], m[2]];
  }

  async sendRequest(prompt: string) {
    const configuration = new Configuration({
      apiKey: process.env.OPENAI_API_KEY,
    });
    const openai = new OpenAIApi(configuration);

    const completion = await openai.createCompletion({
      model: "text-davinci-003",
      prompt,
      temperature: 0.9,
      max_tokens: 150,
      top_p: 1,
      frequency_penalty: 0,
      presence_penalty: 0.6,
      stop: [" Human:", " AI:"],
    });
    return completion.data.choices;
  }
}


(async () => {
  const main = new Main();
  await main.run(argv);
})();