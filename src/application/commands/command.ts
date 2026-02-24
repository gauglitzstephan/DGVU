import type { CommandContext } from "./types";

export type CommandResult<T> = {
  data: T;
};

export type Command<TInput, TOutput> = (ctx: CommandContext, input: TInput) => Promise<CommandResult<TOutput>>;
