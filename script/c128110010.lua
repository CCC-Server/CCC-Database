--유네티스 케찰코아틀
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 설정
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,1,1)
	
	--①: P존 세팅 + 서치 + 특소 제약
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.pccon)
	e1:SetTarget(s.pctg)
	e1:SetOperation(s.pcop)
	c:RegisterEffect(e1)
	
	--②: 추가 일반 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e2:SetTarget(s.extg)
	c:RegisterEffect(e2)
end
s.listed_series={0xc80}

-- [링크 소재]: 스피릿 / 펜듈럼 몬스터 1장
function s.matfilter(c,lc,sumtype,tp)
	return c:IsType(TYPE_SPIRIT,lc,sumtype,tp) and c:IsType(TYPE_PENDULUM,lc,sumtype,tp)
end

-- [효과 ①]: 링크 소환 성공 시
function s.pccon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- 엑스트라 덱(앞면)에서 세팅할 몬스터 필터
function s.pcfilter(c,tp)
	return c:IsFaceup() and c:IsType(TYPE_SPIRIT) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,c:GetLevel())
end
-- 덱/묘지에서 가져올 몬스터 필터
function s.thfilter(c,lv)
	return c:IsType(TYPE_SPIRIT) and c:IsType(TYPE_PENDULUM) and c:IsLevelBelow(lv) and c:IsAbleToHand()
end

function s.pctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp)
		and Duel.IsExistingMatchingCard(s.pcfilter,tp,LOCATION_EXTRA,0,1,nil,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.pcop(e,tp,eg,ep,ev,re,r,rp)
	-- 특수 소환 제약 적용
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	if not Duel.CheckPendulumZones(tp) then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.pcfilter,tp,LOCATION_EXTRA,0,1,1,nil,tp)
	local tc=g:GetFirst()
	if tc then
		if Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true) then
			local lv=tc:GetLevel()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,lv)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	-- 엑스트라 덱에서의 특수 소환 제한: "유네티스" 몬스터만 가능
	-- (소재 조건을 텍스트로 확인하는 것은 스크립트 한계상 생략하고 카드군으로 대체함)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsSetCard(0xc80)
end

-- [효과 ②]: 추가 일반 소환 대상 (스피릿/펜듈럼)
function s.extg(e,c)
	return c:IsType(TYPE_SPIRIT) and c:IsType(TYPE_PENDULUM)
end