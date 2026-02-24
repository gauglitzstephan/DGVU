export type CommandContext = {
  organisationId: string;
  actorUserId?: string; // nullable for system jobs only
};
