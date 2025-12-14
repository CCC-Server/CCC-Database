--정크 싱크론 파트너
local s,id=GetID()
function s.initial_effect(c)
	--①: "싱크론" 튜너 대신 싱크로 소재로 가능
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(20932152)
	c:RegisterEffect(e0)

	--①: 패의 이 카드도 싱크로 소재로 가능 ("싱크론" 튜너를 요구하는 싱크로 몬스터)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_SYNCHRO_MAT_FROM_HAND)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetValue(function(e,mc,sc) return sc:ListsArchetypeAsMaterial(SET_SYNCHRON) end)
	c:RegisterEffect(e1)

	--②: 소환/특소/싱크로 소재로 묘지로 갔을 때 서치
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	local e4=e2:Clone()
	e4:SetCode(EVENT_BE_MATERIAL)
	e4:SetCondition(s.matcon)
	c:RegisterEffect(e4)
end

-- 📌 참조 데이터
s.listed_series={SET_SYNCHRON}
s.listed_names={CARD_JUNK_WARRIOR}

---------------------------------------------------------------
-- ② 효과: "정크 워리어" 언급 몬스터 서치
---------------------------------------------------------------
function s.thfilter(c)
	return c:IsMonster() and c:ListsCode(CARD_JUNK_WARRIOR) and c:IsAbleToHand()
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
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_SYNCHRO
end
