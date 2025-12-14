local s,id=GetID()
function s.initial_effect(c)
	-- ①: Special Summon from hand if 2+ "Fairy Aroma" monsters were Special Summoned this turn
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- Global tracker for "Fairy Aroma" Special Summons
	if not s.global_check then
		s.global_check=true
		s[0]=0
		s[1]=0
		-- Count "Fairy Aroma" Special Summons
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)

		-- Reset counter at start of each Draw Phase
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge2:SetOperation(s.resetcount)
		Duel.RegisterEffect(ge2,0)
	end

	-- ②: On Normal/Special Summon - Search "Fairy Aroma" monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- ③: If sent to GY as Synchro/Link material - Special Summon "Fairy Aroma Token"
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_BE_MATERIAL)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.tkcon)
	e4:SetTarget(s.tktg)
	e4:SetOperation(s.tkop)
	c:RegisterEffect(e4)
end

--------------------------
-- E1: 특수 소환 조건
--------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	for tc in aux.Next(eg) do
		if tc:IsSetCard(0x767) and tc:IsSummonType(SUMMON_TYPE_SPECIAL) then
			local p=tc:GetSummonPlayer()
			s[p]=s[p]+1
		end
	end
end
function s.resetcount(e,tp,eg,ep,ev,re,r,rp)
	s[0]=0
	s[1]=0
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return s[tp]>=2 -- ✅ "요정향" 특수 소환 2번 이상 했는가?
end

--------------------------
-- E2: 서치 효과
--------------------------
function s.thfilter(c)
	return c:IsSetCard(0x767) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------
-- E3: 토큰 생성 효과
--------------------------
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsLocation(LOCATION_GRAVE) and (r==REASON_SYNCHRO or r==REASON_LINK)
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsPlayerCanSpecialSummonMonster(
				tp,128770345,0x767,TYPES_TOKEN,1600,1000,4,RACE_SPELLCASTER,ATTRIBUTE_WIND
			)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(
		tp,128770345,0x767,TYPES_TOKEN,1600,1000,4,RACE_SPELLCASTER,ATTRIBUTE_WIND
	) then return end

	local token=Duel.CreateToken(tp,128770345)
	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
end

