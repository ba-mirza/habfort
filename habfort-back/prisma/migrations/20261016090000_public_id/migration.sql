-- Short shareable id per user (see generatePublicId). Existing users get one
-- here; the subquery references the row so random() runs per user rather
-- than once for the whole statement.
ALTER TABLE "User" ADD COLUMN "publicId" TEXT;

UPDATE "User" SET "publicId" = (
  SELECT string_agg(
    substr('ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789', 1 + floor(random() * 57)::int, 1),
    ''
  )
  FROM generate_series(1, 10 + 0 * length("User"."id"))
);

ALTER TABLE "User" ALTER COLUMN "publicId" SET NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "User_publicId_key" ON "User"("publicId");
