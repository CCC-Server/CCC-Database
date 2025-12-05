--칠흑의 대선풍
--Great Black Gale
local s,id=GetID()
local CARD_BLACK_WHIRLWIND=91351370
function s.initial_effect(c)
	--① Activate: add 1 "BF" monster from Deck to hand, then
	--if you control "Black Whirlwind", you can Normal Summon 1 "BF" monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- 이 카드명의 카드는 1턴에 1장만 발동
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	--② If a "BF" Synchro or "Black-Winged Dragon" is Special Summoned:
	--target 1 card on the field; destroy it.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_SZONE)
	-- 이 카드명의 ②의 효과는 1턴에 1번
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	--③ "BF" monsters you control gain ATK equal to
	--300 x number of different "BF" monsters you control
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.atktg)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)
end

--세트/이름 참조
s.listed_series={SET_BLACKWING}
s.listed_names={CARD_BLACK_WHIRLWIND,CARD_BLACK_WINGED_DRAGON}

--------------------------------
-- ① 발동 효과
--------------------------------
function s.thfilter(c)
	return c:IsSetCard(SET_BLACKWING) and c:IsMonster() and c:IsAbleToHand()
end
function s.bwfilter(c)
	return c:IsFaceup() and c:IsCode(CARD_BLACK_WHIRLWIND)
end
function s.nsfilter(c)
	return c:IsSetCard(SET_BLACKWING) and c:IsSummonable(true,nil)
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 서치 가능한 BF 몬스터가 있을 때만 발동 허용
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	-- 덱에서 "BF" 몬스터 1장 서치
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
	-- 자신 필드에 "검은 선풍"이 있고, 패에 소환 가능한 BF가 있으면
	-- 추가로 1장 일반 소환할 수 있다.
	if Duel.IsExistingMatchingCard(s.bwfilter,tp,LOCATION_ONFIELD,0,1,nil)
		and Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
		local sc=sg:GetFirst()
		if sc then
			Duel.Summon(tp,sc,true,nil)
		end
	end
end

--------------------------------
-- ② 파괴 효과
--------------------------------
function s.trigfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp)
		and ((c:IsSetCard(SET_BLACKWING) and c:IsType(TYPE_SYNCHRO))
			or c:IsCode(CARD_BLACK_WINGED_DRAGON))
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.trigfilter,1,nil,tp)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

--------------------------------
-- ③ 공격력 상승 효과
--------------------------------
function s.bffilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_BLACKWING) and c:IsMonster()
end
function s.atktg(e,c)
	return c:IsSetCard(SET_BLACKWING) and c:IsMonster()
end
function s.atkval(e,c)
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.bffilter,tp,LOCATION_MZONE,0,nil)
	local ct=g:GetClassCount(Card.GetCode) -- 서로 다른 이름 수
	return ct*300
end
