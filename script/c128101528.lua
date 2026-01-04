--환마의 집행관
--Executor of the Phantom Demon
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 제약: 공격력 0/수비력 0의 악마족 1장을 포함하는 몬스터 2장
	c:EnableReviveLimit()
	Link.AddProcedure(c,nil,2,2,s.lcheck)
	
	--①: 링크 소환 성공 시 삼환마 특수 소환 + 조건부 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--②: 상대 소환 시 묘지 회수 및 드로우
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.tdcon)
	e2:SetTarget(s.tdtg)
	e2:SetOperation(s.tdop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

--삼환마 및 실락원 리스트
s.listed_names={6007213,32491822,69890967,13301895}

--링크 소재 체크 (공/수 0 악마족 포함 여부)
function s.matfilter(c)
	return c:IsRace(RACE_FIEND) and c:IsAttack(0) and c:IsDefense(0)
end
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(s.matfilter,1,nil)
end

--1번 효과 로직
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

--삼환마 특수 소환용 필터
function s.spfilter(c,e,tp)
	return c:IsCode(6007213,32491822,69890967) 
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false) -- 소환 조건 무시 필수
end

--삼환마 혹은 관련 카드 서치용 필터 (초래신 로직 참고)
function s.thfilter(c)
	return (c:IsCode(6007213,32491822,69890967) or c:ListsCode(6007213,32491822,69890967))
		and not c:IsCode(id) and c:IsAbleToHand()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	
	--삼환마 특수 소환
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)>0 then
		--필드에 실락원(13301895)이 있으면 추가 서치
		local fc=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,13301895),tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
		if fc and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local g2=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
			if #g2>0 then
				Duel.SendtoHand(g2,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,g2)
			end
		end
	end
end

--2번 효과 로직
function s.tdcon(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp -- 상대가 소환했을 때
end

function s.tdfilter1(c) -- 본체 삼환마
	return c:IsCode(6007213,32491822,69890967) and c:IsAbleToDeck()
end

function s.tdfilter2(c) -- 삼환마 관련 카드
	return (c:IsCode(6007213,32491822,69890967) or c:ListsCode(6007213,32491822,69890967)) 
		and c:IsAbleToDeck()
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b1=Duel.IsExistingMatchingCard(s.tdfilter1,tp,LOCATION_GRAVE,0,1,c)
	local b2=Duel.IsExistingMatchingCard(s.tdfilter2,tp,LOCATION_GRAVE,0,2,nil)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) and (b1 or b2) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local b1=Duel.IsExistingMatchingCard(s.tdfilter1,tp,LOCATION_GRAVE,0,1,c)
	local b2=Duel.IsExistingMatchingCard(s.tdfilter2,tp,LOCATION_GRAVE,0,2,nil)
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	elseif b1 then op=0 else op=1 end
	
	local g=Group.CreateGroup()
	if op==0 then
		--이 카드 + 삼환마 1장 회수
		g:AddCard(c)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g1=Duel.SelectMatchingCard(tp,s.tdfilter1,tp,LOCATION_GRAVE,0,1,1,c)
		g:Merge(g1)
	else
		--관련 카드 2장 회수
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g2=Duel.SelectMatchingCard(tp,s.tdfilter2,tp,LOCATION_GRAVE,0,2,2,nil)
		g:Merge(g2)
	end
	
	if #g>0 then
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		local og=Duel.GetOperatedGroup()
		if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then Duel.ShuffleDeck(tp) end
		local ct=og:FilterCount(Card.IsLocation,nil,LOCATION_DECK|LOCATION_EXTRA)
		if ct>0 then
			Duel.BreakEffect()
			Duel.Draw(tp,1,REASON_EFFECT)
		end
	end
end