import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/all-exceptions.filter';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  // Railway terminates TLS in front of the app, so the client address only
  // exists in X-Forwarded-For — without this every request looks like it comes
  // from the proxy, which would lump all users into one rate-limit bucket.
  app.set('trust proxy', 1);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());

  const configService = app.get(ConfigService);
  app.enableCors({
    origin: configService.getOrThrow<string>('app.corsOrigin'),
  });

  // /docs would otherwise be a public map of the API on the deployed instance.
  if (!configService.get<boolean>('app.isProduction')) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('Habits API')
      .setDescription('Habit tracker with a token economy')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const swaggerDocument = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('docs', app, swaggerDocument);
  }

  const port = configService.getOrThrow<number>('app.port');
  await app.listen(port);
}
void bootstrap();
