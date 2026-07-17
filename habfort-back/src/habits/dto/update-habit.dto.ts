import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

// Deliberately narrow: type/difficulty/schedule are fixed at creation time —
// changing them after the fact would need to interact with completion logic
// (Phase 4+) that doesn't exist yet. Renaming is the one always-safe edit.
export class UpdateHabitDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name!: string;
}
