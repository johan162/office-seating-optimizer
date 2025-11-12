
export type Weekday = 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday';

export const WEEKDAYS: Weekday[] = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

export interface Person {
  name: string;
  team: string;
}

export interface Team {
  name:string;
  members: Person[];
  size: number;
  leastFavorableDay: Weekday | null;
}

export interface SolutionAssignment {
  teamName: string;
  days: Weekday[];
}

export interface DailyHeadcount {
  Monday: number;
  Tuesday: number;
  Wednesday: number;
  Thursday: number;
  Friday: number;
}

export interface Solution {
  assignments: SolutionAssignment[];
  score: number;
  dailyHeadcount: DailyHeadcount;
}
