import {
  ValidationArguments,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';
import { HabitType, RecurringScheduleType } from '../../../generated/prisma';

interface HabitTypeFields {
  type: HabitType;
  requiredDays?: number;
  scheduleType?: RecurringScheduleType;
  scheduleDays?: number[];
}

@ValidatorConstraint({ name: 'habitFieldsMatchType', async: false })
export class HabitFieldsMatchTypeConstraint implements ValidatorConstraintInterface {
  validate(_: unknown, args: ValidationArguments): boolean {
    const dto = args.object as HabitTypeFields;

    if (dto.type === HabitType.CONDITIONAL) {
      return (
        typeof dto.requiredDays === 'number' &&
        dto.scheduleType === undefined &&
        dto.scheduleDays === undefined
      );
    }

    if (dto.type === HabitType.RECURRING) {
      if (dto.requiredDays !== undefined || dto.scheduleType === undefined) {
        return false;
      }
      if (dto.scheduleType === RecurringScheduleType.DAYS_OF_WEEK) {
        return Array.isArray(dto.scheduleDays) && dto.scheduleDays.length > 0;
      }
      return dto.scheduleDays === undefined;
    }

    // INSTANT
    return (
      dto.requiredDays === undefined &&
      dto.scheduleType === undefined &&
      dto.scheduleDays === undefined
    );
  }

  defaultMessage(): string {
    return (
      'requiredDays is required only for CONDITIONAL habits; scheduleType is required only for RECURRING habits ' +
      '(scheduleDays is required only when scheduleType is DAYS_OF_WEEK)'
    );
  }
}
